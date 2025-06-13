
# Cluster Information
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

# Networking Information
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# IAM Information
output "eks_node_group_role_arn" {
  description = "EKS node group IAM role ARN"
  value       = module.iam_final.eks_node_group_role_arn
}

output "github_oidc_role_arn" {
  description = "GitHub OIDC IAM role ARN"
  value       = module.iam_final.github_oidc_role_arn
}

# Database Information
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_secret_arn" {
  description = "Secrets Manager secret ARN for RDS credentials"
  value       = module.rds.secret_arn
}

# ECR Information
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.ecr_repos
}

# Monitoring Information
output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${module.monitoring.grafana_endpoint}"
}

output "prometheus_url" {
  description = "Prometheus dashboard URL"
  value       = "http://${module.monitoring.prometheus_endpoint}"
}

# # Ingress Information
# output "ingress_endpoint" {
#   description = "NGINX ingress controller endpoint"
#   value       = module.ingress.endpoint
# }

# Combined Outputs
output "connection_instructions" {
  description = "Instructions for connecting to the cluster"
  value = <<EOT
To connect to your EKS cluster:

1. Configure kubectl:
   aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}

2. Database connection:
   Host: ${module.rds.endpoint}
   Username: ${var.db_username}
   Password: See Secrets Manager (${module.rds.secret_arn})

3. Grafana Dashboard:
   URL: http://${module.monitoring.grafana_endpoint}
   Username: admin
   Password: ${var.grafana_admin_password}
EOT
  sensitive = true
}

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    eks_cluster    = module.eks.cluster_name
    node_groups    = module.node_group.node_group_names
    rds_instance   = module.rds.db_instance_id
    ecr_repos      = keys(module.ecr.ecr_repos)
    vpc_id         = module.vpc.vpc_id
    deployed_at    = timestamp()
  }
}












# # EKS Outputs
# output "eks_cluster_name" {
#   value = module.eks.cluster_name
# }

# output "rds_endpoint" {
#   value = module.rds.endpoint
# }


# # VPC Outputs
# output "vpc_id" {
#   value       = module.vpc.vpc_id
#   description = "VPC ID"
# }

# output "public_subnet_ids" {
#   value       = module.vpc.public_subnet_ids
#   description = "List of public subnet IDs"
# }

# output "private_subnet_ids" {
#   value       = module.vpc.private_subnet_ids
#   description = "List of private subnet IDs"
# }

# output "private_sg_id" {
#   value       = module.vpc.private_sg_id
#   description = "Private security group ID"
# }

# # output "github_oidc_role_arn" {
# #   value = module.iam.github_oidc_role_arn
# # }



# output "cluster_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = module.eks.cluster_endpoint
# }

# output "ecr_repository_urls" {
#   description = "Map of ECR repository URLs"
#   value       = module.ecr.ecr_repos
#   sensitive   = true
# }

# output "rds_connection_details" {
#   description = "RDS connection details"
#   value = {
#     endpoint = module.rds.endpoint
#     secret   = aws_secretsmanager_secret.rds_credentials.name
#   }
#   sensitive = true
# }

# output "grafana_admin_password" {
#   description = "Grafana admin password"
#   value       = var.grafana_admin_password
#   sensitive   = true
# }

# # ============================================
# # Root outputs.tf (or wherever you define outputs)
# # ============================================
# # output "nginx_elb_hostname" {
# #   description = "Hostname of the AWS LoadBalancer for nginx-ingress"
# #   value       = data.kubernetes_service.nginx_ingress_lb.status[0].load_balancer[0].ingress[0].hostname
# # }

# # output "nginx_elb_hostname" {
# #   description = "DNS name of the AWS Load Balancer created by ingress-nginx"
# #   value       = data.aws_lb.nginx_ingress.dns_name
# # }
