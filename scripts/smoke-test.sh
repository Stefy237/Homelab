#!/usr/bin/env bash

set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$(pwd)/kubeconfig}"

k() { kubectl "$@"; }
fail() { echo "ÉCHEC : $*" >&2; exit 1; }

cleanup() {
    k delete deployment/smoke-web service/smoke-web --ignore-not-found
    k delete -f k8s/tests/pvc-test.yaml --ignore-not-found
}
trap cleanup EXIT

echo "1/4 Trois nœuds Ready"
ready=$(k get nodes --no-headers | awk '$2 == "Ready"' | wc -l)
[ "$ready" -eq 3 ] || fail "$ready nœud(s) Ready sur 3"

echo "2/4 DNS interne"
k run smoke-dns --image=busybox:1.36 --rm -i --restart=Never -- \
    nslookup kubernetes.default.svc.cluster.local

echo "3/4 Service LoadBalancer"
k create deployment smoke-web --image=nginx --replicas=2
k expose deployment smoke-web --port=80 --type=LoadBalancer
k rollout status deployment/smoke-web --timeout=120s

IP=""
for _ in $(seq 30); do
    IP=$(k get service smoke-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    [ -n "$IP" ] && break
    sleep 2
done
[ -n "$IP" ] || fail "aucune IP attribuée par MetalLB après 60 s"
curl -sf --retry 3 "http://$IP" > /dev/null || fail "pas de réponse HTTP sur $IP"
echo "Réponse reçue sur $IP"

echo "4/4 Stockage persistant"
k apply -f k8s/tests/pvc-test.yaml
k wait --for=condition=Ready pod/smoke-pvc --timeout=120s
k exec smoke-pvc -- cat /data/ok

echo "Tous les tests sont passés"
