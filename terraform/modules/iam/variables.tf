variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "github_org" {
  description = "GitHub Organization Name"
  type        = string
}

variable "repo_name" {
  description = "GitHub Repository Name"
  type        = string
}

variable "github_branch" {
  default = "main"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  
}