#!/usr/bin/env bash

set -euo pipefail

ACCOUNT_ID="${1:?Usage: $0 <ACCOUNT_ID> <S3_BUCKET_NAME> [REGION]}"
S3_BUCKET="${2:?Usage: $0 <ACCOUNT_ID> <S3_BUCKET_NAME> [REGION]}"
REGION="${3:-ap-southeast-3}"

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${ECR_URL}/nexus3:3.68.0"
CLUSTER_NAME="nexus-cluster"
NAMESPACE="nexus"

# ---------------------------------------------------------------------------
# Step 1 — Create ECR repository (idempotent) and push image
# ---------------------------------------------------------------------------
echo "==> Creating ECR repository (if not exists)"
aws ecr describe-repositories --repository-names nexus3 --region "${REGION}" 2>/dev/null || \
  aws ecr create-repository --repository-name nexus3 --region "${REGION}"

echo "==> Authenticating Docker to ECR"
aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${ECR_URL}"

echo "==> Building Nexus image"
docker build -t "${IMAGE}" docker/

echo "==> Pushing image to ECR"
docker push "${IMAGE}"

# ---------------------------------------------------------------------------
# Step 2 — Provision AWS infrastructure with Terraform
# ---------------------------------------------------------------------------
echo "==> Initialising Terraform"
cd terraform
terraform init -input=false

echo "==> Applying Terraform"
terraform apply -input=false -auto-approve \
  -var="s3_bucket_name=${S3_BUCKET}" \
  -var="region=${REGION}"

IRSA_ROLE_ARN=$(terraform output -raw nexus_irsa_role_arn)
cd ..

# ---------------------------------------------------------------------------
# Step 3 — Configure kubectl
# ---------------------------------------------------------------------------
echo "==> Fetching EKS credentials"
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

# ---------------------------------------------------------------------------
# Step 4 — Helm deploy
# ---------------------------------------------------------------------------
echo "==> Creating Kubernetes namespace"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing / upgrading Nexus via Helm"
helm upgrade --install nexus k8s/helm/nexus \
  --namespace "${NAMESPACE}" \
  --set image.repository="${ECR_URL}/nexus3" \
  --set image.tag="3.68.0" \
  --set s3.bucketName="${S3_BUCKET}" \
  --set s3.region="${REGION}" \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${IRSA_ROLE_ARN}" \
  --wait --timeout=8m

# ---------------------------------------------------------------------------
# Step 5 — Print access info
# ---------------------------------------------------------------------------
echo ""
echo "==> Waiting for LoadBalancer hostname…"
sleep 30

EXTERNAL_HOST=$(kubectl get svc nexus -n "${NAMESPACE}" \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "<pending>")

echo ""
echo "======================================================"
echo "  Nexus UI : http://${EXTERNAL_HOST}:8081"
echo ""
echo "  Get admin password:"
echo "    kubectl exec -n ${NAMESPACE} deploy/nexus -- cat /nexus-data/admin.password"
echo ""
echo "  Configure S3 blob store after first login:"
echo "    Administration → Blob Stores → Create → S3"
echo "    Bucket : ${S3_BUCKET}"
echo "    Region : ${REGION}"
echo "======================================================"
