# ────────────────────────────────────────
# root provider.tf
# ────────────────────────────────────────

provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}
