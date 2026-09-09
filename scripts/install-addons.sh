#!/usr/bin/env bash
# Install Cluster Autoscaler, AWS Load Balancer Controller, and Prometheus + Grafana.
#
# Prerequisites:
#   - terraform apply completed
#   - kubectl context pointing at the cluster
#   - helm installed
#
# Usage:
#   ./scripts/install-addons.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-three-tier-eks}"

cd "$ROOT/terraform"
CA_ROLE="$(terraform output -raw cluster_autoscaler_role_arn)"
LB_ROLE="$(terraform output -raw aws_lb_controller_role_arn)"
VPC_ID="$(terraform output -raw vpc_id)"
cd "$ROOT"

echo "==> Helm repos"
helm repo add autoscaler https://kubernetes.github.io/autoscaler >/dev/null 2>&1 || true
helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

echo "==> Cluster Autoscaler"
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName="$CLUSTER_NAME" \
  --set awsRegion="$REGION" \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$CA_ROLE" \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.skip-nodes-with-system-pods=false

echo "==> AWS Load Balancer Controller"
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$REGION" \
  --set vpcId="$VPC_ID" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$LB_ROLE"

echo "==> Prometheus + Grafana (integrated)"
"$ROOT/scripts/install-monitoring.sh"

echo
echo "Verify addons:"
echo "  kubectl get pods -n kube-system"
echo "  kubectl logs -f -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"
echo "  kubectl logs -f -n kube-system -l app=cluster-autoscaler"
echo "  kubectl -n monitoring get pods"
echo "  kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80"
