#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MQTT_CONTAINER_NAME="emqx-test"
MQTT_HOST="localhost"
MQTT_PORT="1883"
MQTT_USERNAME="admin"
MQTT_PASSWORD="public"
TEST_TOPIC="messages-in01"
TEST_MESSAGE="Hello to MQTT Spin Component!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

cleanup() {
    log "Cleaning up test environment..."
    
    # Kill spin process if running
    if [ ! -z "${SPIN_PID:-}" ]; then
        if kill -0 "$SPIN_PID" 2>/dev/null; then
            log "Stopping Spin application (PID: $SPIN_PID)..."
            kill "$SPIN_PID"
            wait "$SPIN_PID" 2>/dev/null || true
            log "Spin application stopped"
        fi
    fi
    
    # Stop and remove MQTT broker container
    docker stop "$MQTT_CONTAINER_NAME" 2>/dev/null || true
    docker rm "$MQTT_CONTAINER_NAME" 2>/dev/null || true
    
    log "Cleanup completed"
}

# Set up cleanup trap
trap cleanup EXIT

check_dependencies() {
    log "Checking dependencies..."
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        error "Docker is required but not installed"
        exit 1
    fi
    
    # Check if mqttx is available
    if ! command -v mqttx &> /dev/null; then
        error "mqttx CLI is required but not installed. Run 'brew install emqx/mqttx/mqttx-cli' or see installation instructions: https://mqttx.app/docs/get-started"
            exit 1
    fi
    
    # Check if spin is available
    if ! command -v spin &> /dev/null; then
        error "Spin CLI is required but not installed"
        exit 1
    fi
    
    log "Dependencies check completed"
}

start_mqtt_broker() {
    log "Starting MQTT broker..."
    
    # Stop existing container if running
    docker stop "$MQTT_CONTAINER_NAME" 2>/dev/null || true
    docker rm "$MQTT_CONTAINER_NAME" 2>/dev/null || true
    
    # Start EMQX broker
    docker run -d \
        --name "$MQTT_CONTAINER_NAME" \
        -p 1883:1883 \
        -p 8083:8083 \
        -p 8883:8883 \
        -p 8084:8084 \
        -p 18083:18083 \
        emqx/emqx
    
    log "Waiting for MQTT broker to be ready..."
    
    # Wait for broker to be ready (max 30 seconds)
    for i in {1..30}; do
        if mqttx pub -t "testing" -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" -m "test message" &>/dev/null; then
            log "MQTT broker is ready"
            return 0
        fi
        sleep 1
    done
    
    error "MQTT broker failed to start or is not accessible"
    docker logs "$MQTT_CONTAINER_NAME"
    exit 1
}

build_and_install_plugin() {
    log "Building and installing MQTT plugin..."
    
    cd "$PROJECT_DIR"
    
    # Run make to build and install plugin
    make clean || true
    make
    
    log "Plugin built and installed successfully"
}

start_spin_app() {
    log "Starting Spin application..."
    
    cd "$PROJECT_DIR"
    
    # Create log file for spin output (overwrite if exists)
    SPIN_LOG_DIR="$PROJECT_DIR/logs"
    SPIN_LOGS_STDOUT="$SPIN_LOG_DIR/mqtt-c01_stdout.txt"
    
    # Build and start the example app in background, capturing output
    spin build --up --from examples/mqtt-app/spin.toml --log-dir "$SPIN_LOG_DIR" &
    SPIN_PID=$!
    
    log "Waiting for Spin application to start..."
    
    # Wait for spin app to be ready (max 30 seconds)
    for i in {1..30}; do
        if kill -0 "$SPIN_PID" 2>/dev/null; then
            sleep 2  # Give it a bit more time to fully initialize
            log "Spin application is running (PID: $SPIN_PID)"
            log "Spin logs being written to: $SPIN_LOG_DIR"
            return 0
        fi
        sleep 1
    done
    
    error "Spin application failed to start"
    exit 1
}

test_mqtt_message_flow() {
    log "Testing MQTT message flow..."
    
    # Give the system a moment to stabilize
    sleep 3
    
    log "Publishing test message to topic '$TEST_TOPIC'..."
    
    # Publish message to MQTT broker
    mqttx pub \
        -t "$TEST_TOPIC" \
        -h "$MQTT_HOST" \
        -p "$MQTT_PORT" \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -m "$TEST_MESSAGE"
    
    log "Message published successfully"
    
    # Wait a bit for message processing
    sleep 5
    
    # Check if spin process is still running (it should be)
    if ! kill -0 "$SPIN_PID" 2>/dev/null; then
        error "Spin application stopped unexpectedly"
        exit 1
    fi
    
    # Check if the test message appears in the spin logs
    log "Checking if Spin application received the message..."
    if grep -q "$TEST_MESSAGE" "$SPIN_LOGS_STDOUT"; then
        log "✅ SUCCESS: Test message found in Spin application output!"
    else
        error "❌ FAILURE: Test message '$TEST_MESSAGE' not found in Spin output"
        log "Full Spin output:"
        cat "$SPIN_LOGS_STDOUT"
        exit 1
    fi

    rm -rf "$SPIN_LOG_DIR" || true
    
    log "MQTT message flow test completed successfully"
}

run_integration_test() {
    log "Starting MQTT Trigger Plugin Integration Test"
    log "=============================================="
    
    check_dependencies
    start_mqtt_broker
    build_and_install_plugin
    start_spin_app
    test_mqtt_message_flow
    
    log "=============================================="
    log "Integration test completed successfully!"
}

# Run the test if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_test
fi