variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-3"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "nexus-cluster"
}

variable "s3_bucket_name" {
  description = "S3 bucket name used as Nexus blob store"
  type        = string
}

variable "nexus_role_name" {
  description = "Name of the IAM role used by Nexus pods (IRSA)"
  type        = string
  default     = "nexus-irsa-role"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace where Nexus is deployed"
  type        = string
  default     = "nexus"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name for Nexus"
  type        = string
  default     = "nexus-sa"
}
