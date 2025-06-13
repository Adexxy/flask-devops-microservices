variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for worker nodes"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_security_group_id" {
  description = "Additional security group ID for the cluster"
  type        = string
  default     = ""
}

variable "azs" {
  description = "Availability zones for the cluster"
  type        = list(string)
}









# variable "cluster_name" {
#   description = "List of subnet IDs for the RDS subnet group"
#   type        = string
# }

# variable "subnet_ids" {
#   description = "List of subnet IDs for the RDS subnet group"
#   type        = list(string)
# }

# variable "vpc_id" {
#   description = "The ID of the VPC where the EKS cluster will be deployed"
#   type        = string
# }

# variable "node_role_arn" {
#   description = "The ARN of the IAM role for the EKS nodes"
#   type        = string
# }

# variable "azs" {
#   description = "List of Availability Zones"
#   type        = list(string)
# }

# variable "private_subnets" {
#   description = "List of private subnet IDs for the EKS cluster"
#   type        = list(string)
# }

# variable "environment" {
#   description = "Environment for the EKS cluster (e.g., dev, prod)"
#   type        = string
# }

# # variable "map_users" {
# #   description = "List of IAM users to add to aws-auth configmap"
# #   type        = list(any)
# #   default     = []
# # }

# variable "map_users" {
#   type = list(object({
#     userarn  = string
#     username = string
#     groups   = list(string)
#   }))
#   default = []
# }


# variable "map_roles" {
#   description = "List of IAM roles to add to aws-auth configmap"
#   type        = list(any)
#   default     = []
# }

# variable "cluster_security_group_id" {
#   type        = string
#   description = "Additional security group ID for the cluster"
# }

# variable "cluster_endpoint_public_access_cidrs" {
#   type        = list(string)
#   default     = ["0.0.0.0/0"]
#   description = "List of CIDR blocks that can access the EKS public endpoint"
# }
