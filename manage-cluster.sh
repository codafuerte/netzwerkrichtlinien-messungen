# Taken from: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/  

# Forwarding IPv4 and letting iptables see bridged traffic (see https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
prepare_container_runtime() {
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter

    # sysctl params required by setup, params persist across reboots
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    # Apply sysctl params without reboot
    sudo sysctl --system
}

setup_containerd() {
    sudo chmod 777 /etc/containerd -R
    sudo containerd config default>/etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd
}

# In order for kubernetes to run, swap needs to be turned off. 
disable_swap() {
    echo "comment out the swap configuration."
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
    sudo swapoff -a
}

install_kubernetes_dependencies() {
    echo "Update the apt package index and install packages needed to use the Kubernetes apt repository:"
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    echo "Download the Google Cloud public signing key:"
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "Add the Kubernetes apt repository:"
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    echo "Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:"
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
}

install_cilium_cli() {
    echo "download cilium-cli tar file & checksum file" 
    curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
    echo "Checking checksum"
    sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
    echo "unpack cilium-cli tar file"
    sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
    rm cilium-linux-amd64.tar.gz && rm cilium-linux-amd64.tar.gz.sha256sum
}

install_skaffold() {
    echo "Start installing Skaffold..."
    echo "Downloading latest stable release of Skaffold"
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
    echo "Installing Skaffold"
    sudo install skaffold /usr/local/bin/ && rm skaffold
    echo "$(skaffold version)"
}

# helm is needed to install cilium in kubeadm cluster
install_helm() {
    echo "downloading helm-tar file"
    curl -O -L https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz
    echo "unpack tar-file"
    sudo tar -zxvf helm-v3.9.0-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm helm-v3.9.0-linux-amd64.tar.gz && sudo rm -r linux-amd64
}

deploy_cilium() {
    case "$1" in 
        helm)
            echo "setup helm repository"
            helm repo add cilium https://helm.cilium.io/
            echo "deploy Cilium to Cluster"
            helm install cilium cilium/cilium --namespace kube-system
            exit 0
            ;;
        cilium-cli)
            echo "deploy Cilium to Cluster"
            cilium install
            exit 0
            ;;
        *)
            echo "Make sure to set 'helm' or 'cilium-cli'"
            exit 1
        ;;
    esac
}

remove_cilium() {
    echo "Remove Cilium from cluster"
    cilium uninstall
}

init_cluster() {
    sudo kubeadm init --config kubernetes/kubeadm-config.yaml
    echo "make kubectl work for non-root user"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

case "$1" in 
    prepare-container-runtime)
        prepare_container_runtime
        exit 0
        ;;
    install-kubernetes-dependencies)
        install_kubernetes_dependencies
        exit 0
        ;;
    install-helm)
        install_helm
        exit 0
        ;;
    deploy-cilium)
        deploy_cilium $2
        exit 0
        ;;
    remove-cilium)
        remove_cilium $2
        exit 0
        ;;
    setup-containerd)
        setup_containerd
        exit 0
        ;;
    disable-swap)
        disable_swap
        exit 0
        ;;
    init-cluster)
        init_cluster $2 $3
        exit 0
        ;;
    setup-cluster-node)
        disable_swap
        install_kubernetes_dependencies
        prepare_container_runtime
        setup_containerd
        exit 0
        ;;
    *)
        echo "provide valid command"
        exit 1
        ;;
esac
    


