# Global Configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod"
  }
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "microservices-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "microservices-cluster"
}

variable "node_instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_taints" {
  description = "Taints to apply to worker nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# RDS Configuration
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "microservices"
}

variable "db_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

# GitHub OIDC Configuration
variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch name"
  type        = string
  default     = "main"
}

variable "github_oidc_role_name" {
  description = "IAM role name for GitHub OIDC"
  type        = string
  default     = "github-actions-oidc"
}

variable "github_oidc_sub" {
  description = "GitHub OIDC subject claim"
  type        = string
  default     = "repo:organization/repository:ref:refs/heads/main"
}

# Monitoring Configuration
variable "grafana_admin_password" {
  description = "Password for Grafana admin user"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_user_id" {
  description = "AWS user ID for admin access"
  type        = string
}

variable "aws_user" {
  description = "AWS username for admin access"
  type        = string
}

# ECR Configuration
variable "ecr_service_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["auth-service", "order-service", "product-service"]
}

# Alerting Configuration
variable "alert_email" {
  description = "Email for receiving alerts"
  type        = string
  default     = "alerts@example.com"
}

variable "public_subnets_cidr" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "alarm_actions" {
  
}

variable "map_roles" {
  description = "Map of IAM roles to Kubernetes roles"
  type        = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default     = []
}

variable "map_users" {
  description = "List of IAM users to add to aws-auth configmap"
  type        = list(any)
  default     = []
}




# # This file defines the variables used in the Terraform configuration for the DevOps Microservices Platform.

# variable "aws_region" {
#   description = "The AWS region to deploy resources in"
#   type        = string
# }

# variable "project_name" {
#   default = "devops-platform"
# }

# variable "cluster_name" {
#   default = "devops-cluster"
# }

# variable "vpc_name" {
#   description = "The name of the VPC"
#   type        = string
# }

# variable "db_username" {
#   description = "The username for the RDS database"
#   type        = string
# }

# variable "vpc_cidr" {
#   description = "CIDR block for the VPC"
#   type        = string
# }

# variable "azs" {
#   description = "A list of availability zones in the region"
#   type        = list(string)
# }

# variable "public_subnets" {
#   description = "List of public subnet CIDRs"
#   type        = list(string)
# }

# variable "private_subnets" {
#   description = "List of private subnet CIDRs"
#   type        = list(string)
# }

# variable "environment" {
#   description = "The environment name (e.g., dev, staging, prod)"
#   type        = string
# }

# variable "s3_bucket_name" {
#   description = "The name of the S3 bucket"
#   type        = string
# }

# variable "s3_key" {
#   description = "The key for the S3 object"
#   type        = string
# }

# variable "db_name" {
#     description = "The name of the RDS database"
#     type        = string
#     default     = "microservices_platform_db"
# }

# variable "db_user" {  
#     description = "The username for the RDS database"
#     type        = string
# }

# variable "db_password" {
#     description = "The password for the RDS database"
#     type        = string
# }

# variable "public_subnets_cidr" {
#   description = "List of public subnet CIDR blocks"
#   type        = list(string)
# }
# variable "private_subnets_cidr" {
#   description = "List of private subnet CIDR blocks"
#   type        = list(string)
# }

# # variable "node_role_arn" {
# #   description = "The ARN of the IAM role for the EKS nodes"
# #   type        = string
# # }

# variable "ecr_service_names" {
#   description = "List of service names for ECR repositories"
#   type        = list(string)
# }

# variable "account_id" {
#   description = "The AWS account ID"
#   type        = string
# }

# variable "github_org" {
#   description = "The GitHub organization name"
#   type        = string
# }

# variable "repo_name" {
#   description = "The name of the GitHub repository"
#   type        = string
# }

# variable "github_branch" {
#   default = "main"
# }

# variable "aws_user" {
#   description = "aws user"
# }

# variable "aws_user_id" {
#   description = "aws user id"
# }

# variable "map_roles" {
#   description = "Map of IAM roles to Kubernetes roles"
#   type        = list(object({
#     rolearn  = string
#     username = string
#     groups   = list(string)
#   }))
#   default     = []
# }

# variable "github_oidc_role_name" {
#   type        = string
#   description = "Name for the GitHub Actions IAM Role"
# }

# variable "github_oidc_sub" {
#   type        = string
#   description = "GitHub OIDC subject: repo:<ORG>/<REPO>:ref:refs/heads/<BRANCH>"
# }

# variable "grafana_admin_password" {
#   description = "Admin password for Grafana"
#   type        = string
#   sensitive   = true
# }

# variable "node_instance_types" {
#   type        = list(string)
#   default     = ["t3.medium"]
#   description = "EC2 instance types for worker nodes"
# }

# variable "node_desired_capacity" {
#   type        = number
#   default     = 2
#   description = "Desired number of worker nodes"
# }

# variable "node_min_size" {
#   type        = number
#   default     = 1
#   description = "Minimum number of worker nodes"
# }

# variable "node_max_size" {
#   type        = number
#   default     = 3
#   description = "Maximum number of worker nodes"
# }

# variable "node_taints" {
#   type = list(object({
#     key    = string
#     value  = string
#     effect = string
#   }))
#   default = []
#   description = "Taints to apply to worker nodes"
# }

# variable "map_users" {
#   description = "List of IAM users to add to aws-auth configmap"
#   type        = list(any)
#   default     = []
# }

# variable "alarm_actions" {
  
# }