# Makefile to build and run MQTT plugin for Spin framework.

.PHONY: all
all: build_plugin install_plugin

.PHONY: lint
lint:
	@echo "Running linting check..."
	cargo clippy --all --all-targets -- -D warnings
	cargo fmt --all -- --check

.PHONY: lint-rust-examples
lint-rust-examples:	
		@echo "Running linting check on example..." \
		&& cargo clippy --manifest-path "examples/mqtt-app/Cargo.toml" -- -D warnings \
		&& cargo fmt --manifest-path "examples/mqtt-app/Cargo.toml" -- --check \

.PHONY: lint-all
lint-all: lint lint-rust-examples

.PHONY: build_plugin
build_plugin:
	@echo "Building Mqtt Plugin..."
	cargo build --release

.PHONY: install_plugin
install_plugin:
	@echo "Installing Mqtt Plugin in Spin..."
	spin plugins update && spin plugins upgrade pluginify -y
	spin pluginify --install
	
.PHONY: clean
clean:
	@echo "Cleaning up..."
	cargo clean
	cargo clean --manifest-path ./examples/mqtt-app/Cargo.toml
	rm -f trigger-mqtt-*.tar.gz
	rm -f trigger-mqtt.json
	spin plugin uninstall trigger-mqtt

.PHONY: test
test:
	@echo "Running integration test..."
	bash tests/integration_test.sh