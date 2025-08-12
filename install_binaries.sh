VERSION="v1.30.1"

curl -LO https://dl.k8s.io/release/${VERSION}/bin/linux/amd64/kube-apiserver
chmod +x kube-apiserver
sudo mv kube-apiserver /usr/local/bin/
