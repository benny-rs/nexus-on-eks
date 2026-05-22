output "eks_cluster_name" {
  value       = aws_eks_cluster.nexus.name
  description = "EKS cluster name"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.nexus.endpoint
  description = "EKS cluster API endpoint"
  sensitive   = true
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.nexus_artifacts.bucket
  description = "S3 bucket used as Nexus blob store"
}

output "nexus_irsa_role_arn" {
  value       = aws_iam_role.nexus_irsa.arn
  description = "IAM role ARN to annotate on the Kubernetes ServiceAccount"
}

output "ecr_repository_url" {
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/nexus3"
  description = "ECR repository URL for the Nexus image"
}

output "get_credentials_command" {
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.nexus.name} --region ${var.region}"
  description = "Run this to configure kubectl"
}
