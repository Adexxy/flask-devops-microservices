# Root outputs.tf to pull all modules together

# EKS Outputs
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}


# VPC Outputs
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "List of private subnet IDs"
}

output "private_sg_id" {
  value       = module.vpc.private_sg_id
  description = "Private security group ID"
}

output "github_oidc_role_arn" {
  value = module.iam.github_oidc_role_arn
}

output "ecr_repository_urls" {
  value       = module.ecr.ecr_repos
  description = "Map of ECR repository URLs"
}

output "ingress_controller_endpoint" {
  value       = "http://${helm_release.nginx_ingress.name}.${helm_release.nginx_ingress.namespace}.svc.cluster.local"
  description = "NGINX Ingress Controller Endpoint"
}
