#!/usr/bin/env bash
set -e

mkdir -p kubeconfigs

API_SERVER="https://192.168.100.100:6443"
CLUSTER_NAME="edgar-home-lab"

# Workers
for host in worker1 worker2 worker3; do
  kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=${API_SERVER} \
    --kubeconfig=kubeconfigs/${host}.kubeconfig

  kubectl config set-credentials system:node:${host} \
    --client-certificate=${host}.crt \
    --client-key=${host}.key \
    --embed-certs=true \
    --kubeconfig=kubeconfigs/${host}.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:node:${host} \
    --kubeconfig=kubeconfigs/${host}.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfigs/${host}.kubeconfig
done

# kube-controller-manager
kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=${API_SERVER} \
  --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.crt \
  --client-key=kube-controller-manager.key \
  --embed-certs=true \
  --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-controller-manager \
  --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

# kube-scheduler
kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=${API_SERVER} \
  --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.crt \
  --client-key=kube-scheduler.key \
  --embed-certs=true \
  --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-scheduler \
  --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

# kube-proxy
kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=${API_SERVER} \
  --kubeconfig=kubeconfigs/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.crt \
  --client-key=kube-proxy.key \
  --embed-certs=true \
  --kubeconfig=kubeconfigs/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-proxy \
  --kubeconfig=kubeconfigs/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfigs/kube-proxy.kubeconfig
