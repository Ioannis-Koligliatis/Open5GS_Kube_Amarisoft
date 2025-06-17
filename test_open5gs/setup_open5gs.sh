#!/bin/bash

set -euo pipefail
LOG_FILE="setup_open5gs.log"
CLUSTER_NAME="open5gs-cluster"
CLUSTER_CONFIG="./clusterconfig.yaml"
MANIFEST_DIR="./open5gs_kubernetes/"

install_k3d() {
    echo "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

install_kubectl() {
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/$(uname | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
}

install_docker() {
    echo "Docker is not installed. Please install it manually from https://docs.docker.com/get-docker/"
    exit 1
}

check_or_install() {
    local cmd=$1
    local installer=$2
    if ! command -v "$cmd" &> /dev/null; then
        read -p "$cmd is not installed. Install now? [Y/n]: " choice
        choice=${choice:-Y}
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            "$installer"
        else
            echo "Cannot proceed without $cmd. Exiting."
            exit 1
        fi
    else
        echo "$cmd is already installed."
    fi
}

create_cluster() {
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
    else
        echo "Creating k3d cluster from $CLUSTER_CONFIG..."
        k3d cluster create -c "$CLUSTER_CONFIG"
    fi
}

wait_for_nodes() {
    echo "Waiting for all Kubernetes nodes to be ready..."
    for i in {1..30}; do
        READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready")
        TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
        if [[ "$READY_NODES" -eq "$TOTAL_NODES" ]]; then
            echo "All $READY_NODES node(s) are ready."
            return
        fi
        sleep 5
    done
    echo "Timeout waiting for nodes to become ready."
    exit 1
}

apply_manifests() {
    if [[ -d "$MANIFEST_DIR" ]]; then
        echo "Applying Open5GS Kubernetes manifests from $MANIFEST_DIR..."
        kubectl apply -f "$MANIFEST_DIR"
    else
        echo "Manifest directory '$MANIFEST_DIR' does not exist. Exiting."
        exit 1
    fi
}

open_browser() {
    # URLs you want to open
    GRAFANA_URL="http://localhost:3000" # Open5Gs Prom+Graf Metrics
    OPEN5GS_WEBUI_URL="http://localhost:9999"  # Open5Gs WebUI
    AMARISOFT_URL="http://192.168.88.53" # Amarisoft gNB

    echo "Attempting to open browser tabs."

    if command -v xdg-open &> /dev/null; then
        xdg-open "$GRAFANA_URL"
        xdg-open "$OPEN5GS_WEBUI_URL"
        xdg-open "$AMARISOFT_URL"
    elif command -v open &> /dev/null; then  # macOS
        open "$GRAFANA_URL"
        open "$OPEN5GS_WEBUI_URL"
        open "$AMARISOFT_URL"
    fi
}


main() {
    echo "----- Starting Open5GS K3D Setup -----"
    check_or_install k3d install_k3d
    check_or_install kubectl install_kubectl
    check_or_install docker install_docker
    create_cluster
    k3d image import gradiant/open5gs:2.7.1 prom/prometheus:v3.4.0 grafana/grafana:12.0.1 mongo:6.0 --cluster open5gs-cluster
    wait_for_nodes

    apply_manifests
    open_browser
    echo "✅ Setup complete!"


}

main "$@"

