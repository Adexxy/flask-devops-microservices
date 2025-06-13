output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.microservices_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.microservices_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data"
  value       = aws_eks_cluster.microservices_cluster.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster"
  value       = aws_eks_cluster.microservices_cluster.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_eks_cluster.microservices_cluster.identity[0].oidc[0].issuer
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.microservices_cluster.version
}