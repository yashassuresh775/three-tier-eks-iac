#!/usr/bin/env bash
# Build amd64 images and push to Amazon ECR.
# Usage: AWS_REGION=us-east-1 ./scripts/build-push-ecr.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
TAG="${IMAGE_TAG:-v1}"

aws ecr describe-repositories --repository-names three-tier-backend --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name three-tier-backend --region "$REGION" >/dev/null
aws ecr describe-repositories --repository-names three-tier-frontend --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name three-tier-frontend --region "$REGION" >/dev/null

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

docker buildx build --platform linux/amd64 -t "${REGISTRY}/three-tier-backend:${TAG}" "$ROOT/app/backend" --push
docker buildx build --platform linux/amd64 -t "${REGISTRY}/three-tier-frontend:${TAG}" "$ROOT/app/frontend" --push

echo "BACKEND_IMAGE=${REGISTRY}/three-tier-backend:${TAG}"
echo "FRONTEND_IMAGE=${REGISTRY}/three-tier-frontend:${TAG}"
