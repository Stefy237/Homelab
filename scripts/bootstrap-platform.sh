#!/usr/bin/env bash
set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$(pwd)/kubeconfig}"

CALICO_VERSION="v3.33.0"
METALLB_VERSION="0.16.1"
LOCAL_PATH_VERSION="v0.0.37"

helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo add metallb https://metallb.github.io/metallb
helm repo update

# 1. Réseau de pods
# Les CRD ne sont plus dans le chart tigera-operator : on les installe d'abord, avec la même version
helm template calico-crds projectcalico/crd.projectcalico.org.v1 \
  --version "$CALICO_VERSION" \
  | kubectl apply --server-side --force-conflicts -f -
kubectl wait --for=condition=Established crd --all --timeout=60s

if ! helm status calico -n tigera-operator >/dev/null 2>&1; then
  helm upgrade --install calico projectcalico/tigera-operator \
    --version "$CALICO_VERSION" \
    --namespace tigera-operator --create-namespace \
    -f k8s/platform/calico/values.yaml
fi
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# 2. LoadBalancer
helm upgrade --install metallb metallb/metallb \
  --version "$METALLB_VERSION" \
  --namespace metallb-system --create-namespace --wait
kubectl apply -f k8s/platform/metallb/pool.yaml

# 3. Stockage
kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/${LOCAL_PATH_VERSION}/deploy/local-path-storage.yaml"
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
