variable "cluster_name" {
  description = "List of subnet IDs for the RDS subnet group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be deployed"
  type        = string
}

# variable "node_role_arn" {
#   description = "The ARN of the IAM role for the EKS nodes"
#   type        = string
# }

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "environment" {
  description = "Environment for the EKS cluster (e.g., dev, prod)"
  type        = string
}

variable "map_users" {
  description = "List of IAM users to add to aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "map_roles" {
  description = "List of IAM roles to add to aws-auth configmap"
  type        = list(any)
  default     = []
}

