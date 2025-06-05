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


# ============================================
# Root outputs.tf (or wherever you define outputs)
# ============================================
# output "nginx_elb_hostname" {
#   description = "Hostname of the AWS LoadBalancer for nginx-ingress"
#   value       = data.kubernetes_service.nginx_ingress_lb.status[0].load_balancer[0].ingress[0].hostname
# }

# output "nginx_elb_hostname" {
#   description = "DNS name of the AWS Load Balancer created by ingress-nginx"
#   value       = data.aws_lb.nginx_ingress.dns_name
# }
