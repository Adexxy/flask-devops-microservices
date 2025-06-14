
output "eks_node_group_role_arn" {
  value = aws_iam_role.eks_node_group_role.arn
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_oidc_role.arn
}
