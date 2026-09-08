#!/usr/bin/env bash
# Disable monitoring before a demo (mirrors workshop "disable monitoring" flow).
set -euo pipefail
helm uninstall monitoring -n monitoring --ignore-not-found || true
kubectl delete namespace monitoring --ignore-not-found
echo "Monitoring stack removed (if it was present)."
