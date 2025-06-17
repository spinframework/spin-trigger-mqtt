# Updates latest stable toolchain for Rust and clippy/fmt for this toolchain
rustup update stable && rustup default stable && rustup component add clippy rustfmt

# Installs wasm32 compiler targets
rustup target add wasm32-wasip1 wasm32-unknown-unknown

# Installs cmake
sudo apt update && sudo apt install cmake -y

# Install Spin
if [ -d "spininstall" ]; then
    echo "Deleting existing spininstall directory..."
    rm -fr spininstall
fi

mkdir spininstall && cd spininstall
curl -fsSL https://developer.fermyon.com/downloads/install.sh | bash
sudo mv spin /usr/local/bin/
cd ../ && rm -fr spininstall

# Install MQTTX client for testing purposes
curl -LO https://www.emqx.com/en/downloads/MQTTX/v1.9.9/mqttx-cli-linux-x64
sudo install ./mqttx-cli-linux-x64 /usr/local/bin/mqttx
rm ./mqttx-cli-linux-x64