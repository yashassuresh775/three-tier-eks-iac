#!/usr/bin/env bash
# Apply Kubernetes manifests after images are built/pushed.
#
# Usage:
#   BACKEND_IMAGE=... FRONTEND_IMAGE=... ./scripts/deploy-k8s.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${BACKEND_IMAGE:?set BACKEND_IMAGE}"
: "${FRONTEND_IMAGE:?set FRONTEND_IMAGE}"
NS=three-tier

echo "==> Namespace"
kubectl apply -f "$ROOT/k8s/namespace.yaml"
kubectl config set-context --current --namespace "$NS" >/dev/null || true

echo "==> PostgreSQL"
kubectl apply -f "$ROOT/k8s/postgres/secret.yaml"
kubectl apply -f "$ROOT/k8s/postgres/deployment.yaml"
kubectl apply -f "$ROOT/k8s/postgres/service.yaml"
kubectl -n "$NS" rollout status deploy/postgres --timeout=180s

echo "==> Backend API"
sed "s|IMAGE_BACKEND|${BACKEND_IMAGE}|g" "$ROOT/k8s/backend/deployment.yaml" | kubectl apply -f -
kubectl apply -f "$ROOT/k8s/backend/service.yaml"
kubectl -n "$NS" rollout status deploy/backend --timeout=180s

echo "==> Frontend"
sed "s|IMAGE_FRONTEND|${FRONTEND_IMAGE}|g" "$ROOT/k8s/frontend/deployment.yaml" | kubectl apply -f -
kubectl apply -f "$ROOT/k8s/frontend/service.yaml"
kubectl -n "$NS" rollout status deploy/frontend --timeout=180s

echo "==> Internet LoadBalancer"
kubectl apply -f "$ROOT/k8s/full_stack_lb.yaml"

echo "Waiting up to ~5 minutes for EXTERNAL-IP…"
for _ in $(seq 1 60); do
  EXT="$(kubectl -n "$NS" get svc full-stack-lb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  if [[ -n "${EXT}" ]]; then
    echo
    echo "App URL: http://${EXT}/"
    kubectl -n "$NS" get svc full-stack-lb
    exit 0
  fi
  sleep 5
done

echo "LoadBalancer address not ready yet — check later with:"
echo "  kubectl -n ${NS} get svc full-stack-lb"
kubectl -n "$NS" get svc full-stack-lb
