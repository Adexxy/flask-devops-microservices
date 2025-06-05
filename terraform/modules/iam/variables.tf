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

variable "github_oidc_role_name" {
  type        = string
  description = "Name for the GitHub Actions IAM Role"
}

variable "github_oidc_sub" {
  type        = string
  description = "GitHub OIDC subject: repo:<ORG>/<REPO>:ref:refs/heads/<BRANCH>"
}
