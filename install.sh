# !/bin/bash

NODE_EXPORTER_VERSION=$(curl -s "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
read -rp "Enter the port number for the Node Exporter (default: 9100): " -e -i "9100" NODE_EXPORTER_PORT

if lsof -i:$NODE_EXPORTER_PORT > /dev/null 2>&1; then
    echo "Port $NODE_EXPORTER_PORT is already in use. Please choose another port."
    exit 1
fi

function download_node_exporter() {
    echo "Downloading Node Exporter v${NODE_EXPORTER_VERSION}..."
    curl -LO https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
    tar -xzf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
    sudo mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin
    rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz node_exporter-$NODE_EXPORTER_VERSION.linux-amd64
}

function create_node_exporter_user() {
    sudo useradd --no-create-home --shell /bin/false node_exporter
}

function create_node_exporter_service() {
    sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:$NODE_EXPORTER_PORT

[Install]
WantedBy=multi-user.target
EOF
}

function start_node_exporter_service() {
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter --now
}

function install_node_exporter() {
    download_node_exporter
    create_node_exporter_user
    create_node_exporter_service
    start_node_exporter_service
}

install_node_exporter
