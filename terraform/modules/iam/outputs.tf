output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub OIDC IAM role"
  value       = aws_iam_role.github_oidc_role.arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the cluster autoscaler IAM role"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS monitoring IAM role"
  value       = aws_iam_role.rds_monitoring.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}