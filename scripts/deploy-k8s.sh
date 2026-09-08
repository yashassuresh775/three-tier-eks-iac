#!/usr/bin/env bash
# Apply Kubernetes manifests after images are built/pushed.
# Usage: BACKEND_IMAGE=... FRONTEND_IMAGE=... ./scripts/deploy-k8s.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${BACKEND_IMAGE:?set BACKEND_IMAGE}"
: "${FRONTEND_IMAGE:?set FRONTEND_IMAGE}"

kubectl apply -f "$ROOT/k8s/namespace.yaml"
kubectl apply -f "$ROOT/k8s/postgres/secret.yaml"
kubectl apply -f "$ROOT/k8s/postgres/deployment.yaml"

sed "s|IMAGE_BACKEND|${BACKEND_IMAGE}|g" "$ROOT/k8s/backend/deployment.yaml" | kubectl apply -f -
sed "s|IMAGE_FRONTEND|${FRONTEND_IMAGE}|g" "$ROOT/k8s/frontend/deployment.yaml" | kubectl apply -f -

kubectl -n three-tier rollout status deploy/postgres
kubectl -n three-tier rollout status deploy/backend
kubectl -n three-tier rollout status deploy/frontend
kubectl -n three-tier get svc frontend
