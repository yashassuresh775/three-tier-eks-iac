#!/usr/bin/env bash
# Remove the integrated Prometheus + Grafana stack (use for teardown / cost control).
set -euo pipefail
helm uninstall monitoring -n monitoring --ignore-not-found || true
kubectl delete namespace monitoring --ignore-not-found
echo "Prometheus + Grafana stack removed (if it was present)."
