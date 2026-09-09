#!/usr/bin/env bash
# Install integrated Prometheus + Grafana (kube-prometheus-stack).
# This is a required three-tier-eks-iac component — not optional.
#
# Usage: ./scripts/install-monitoring.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Helm repo (prometheus-community)"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

echo "==> Installing kube-prometheus-stack (Prometheus + Grafana)"
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f "$ROOT/monitoring/prometheus-values.yaml" \
  --wait --timeout 10m

echo
echo "Monitoring ready."
echo "  kubectl -n monitoring get pods"
echo "  kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80"
echo "  Login: admin / prom-operator  |  Dashboard 1860 is pre-loaded"
echo "  After app deploy: kubectl apply -f k8s/backend/servicemonitor.yaml"
