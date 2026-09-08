#!/usr/bin/env bash
# Build amd64 images and push to Amazon ECR (private).
# Works on Mac (buildx) and Linux/Windows Docker Desktop.
#
# Usage:
#   AWS_REGION=us-east-1 IMAGE_TAG=v1 ./scripts/build-push-ecr.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
PROJECT="${PROJECT_NAME:-three-tier-eks}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
TAG="${IMAGE_TAG:-v1}"
BACKEND_REPO="${PROJECT}-backend"
FRONTEND_REPO="${PROJECT}-frontend"

ensure_repo() {
  local name="$1"
  if ! aws ecr describe-repositories --repository-names "$name" --region "$REGION" >/dev/null 2>&1; then
    aws ecr create-repository --repository-name "$name" --region "$REGION" \
      --image-scanning-configuration scanOnPush=true >/dev/null
  fi
}

ensure_repo "$BACKEND_REPO"
ensure_repo "$FRONTEND_REPO"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

BACKEND_IMAGE="${REGISTRY}/${BACKEND_REPO}:${TAG}"
FRONTEND_IMAGE="${REGISTRY}/${FRONTEND_REPO}:${TAG}"

if docker buildx version >/dev/null 2>&1; then
  export DOCKER_CLI_EXPERIMENTAL=enabled
  docker buildx build --platform linux/amd64 -t "$BACKEND_IMAGE" "$ROOT/app/backend" --push
  docker buildx build --platform linux/amd64 -t "$FRONTEND_IMAGE" "$ROOT/app/frontend" --push
else
  docker build -t "$BACKEND_IMAGE" "$ROOT/app/backend"
  docker build -t "$FRONTEND_IMAGE" "$ROOT/app/frontend"
  docker push "$BACKEND_IMAGE"
  docker push "$FRONTEND_IMAGE"
fi

echo
echo "BACKEND_IMAGE=${BACKEND_IMAGE}"
echo "FRONTEND_IMAGE=${FRONTEND_IMAGE}"
echo
echo "Export them, then deploy:"
echo "  export BACKEND_IMAGE=${BACKEND_IMAGE}"
echo "  export FRONTEND_IMAGE=${FRONTEND_IMAGE}"
echo "  ./scripts/deploy-k8s.sh"
