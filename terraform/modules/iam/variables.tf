variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name (for role naming)"
  type        = string
  default     = ""
}

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
  description = "Name for the GitHub OIDC role"
  type        = string
  default     = "github-actions-oidc"
}

variable "github_oidc_sub" {
  description = "GitHub OIDC subject claim"
  type        = string
  default     = ""
}

















# variable "environment" {
#   description = "Deployment environment"
#   type        = string
# }

# variable "account_id" {
#   description = "AWS Account ID"
#   type        = string
# }

# variable "github_org" {
#   description = "GitHub Organization Name"
#   type        = string
# }

# variable "repo_name" {
#   description = "GitHub Repository Name"
#   type        = string
# }

# variable "github_branch" {
#   default = "main"
# }

# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
#   default     = ""
# }

# variable "github_oidc_role_name" {
#   type        = string
#   description = "Name for the GitHub Actions IAM Role"
# }

# variable "github_oidc_sub" {
#   type        = string
#   description = "GitHub OIDC subject: repo:<ORG>/<REPO>:ref:refs/heads/<BRANCH>"
# }
