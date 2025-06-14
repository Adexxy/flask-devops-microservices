# Root main.tf to pull all modules together

# Root main.tf - Complete EKS Microservices Platform

data "aws_caller_identity" "current" {}

# Core Infrastructure
module "vpc" {
  source                = "./modules/vpc"
  name                  = var.vpc_name
  vpc_name              = var.vpc_name
  aws_region            = var.aws_region
  azs                   = var.azs
  vpc_cidr              = var.vpc_cidr
  public_subnets        = var.public_subnets
  private_subnets       = var.private_subnets
  public_subnets_cidr   = var.public_subnets_cidr
  private_subnets_cidr  = var.private_subnets_cidr
  environment           = var.environment
}

module "iam" {
  source                = "./modules/iam"
  environment           = var.environment
  account_id            = data.aws_caller_identity.current.account_id
  github_org            = var.github_org
  cluster_name          = var.cluster_name
  repo_name             = var.repo_name
  github_branch         = var.github_branch
  github_oidc_role_name = var.github_oidc_role_name
  github_oidc_sub       = var.github_oidc_sub
}

# EKS Cluster
module "eks" {
  source          = "./modules/eks"
  subnet_ids      = module.vpc.private_subnet_ids
  vpc_id          = module.vpc.vpc_id
  cluster_name    = var.cluster_name
  azs             = var.azs
  private_subnets = module.vpc.private_subnet_ids
  environment     = var.environment

  terraform_user_arn = data.aws_caller_identity.current.arn
  admin_principal_arns = concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.aws_user}",
    module.iam.github_oidc_role_arn
  ], var.admin_principal_arns)
}

module "node_group" {
  source            = "./modules/node_group"
  cluster_name      = module.eks.cluster_name
  cluster_arn       = module.eks.cluster_arn # Add this line
  node_group_name   = "${var.environment}-node-group"
  subnet_ids        = module.vpc.private_subnet_ids
  node_role_arn     = module.iam.eks_node_group_role_arn
  instance_types    = ["t3.medium"]
  desired_capacity  = 2
  min_size          = 1
  max_size          = 3
  environment       = var.environment
}

# Database
module "rds" {
  source          = "./modules/rds"
  db_name         = var.db_name
  db_user         = var.db_username
  db_password     = var.db_password
  subnet_ids      = module.vpc.private_subnet_ids
  security_groups = [module.vpc.private_sg_id]
  environment     = var.environment
}

# Container Registry
module "ecr" {
  source        = "./modules/ecr"
  service_names = var.ecr_service_names
  environment   = var.environment
}

# Kubernetes Configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region,
      # "--role-arn",
      # data.aws_caller_identity.current.arn
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [
    module.eks,
    module.node_group,
    # aws_eks_access_policy_association.terraform_admin
  ]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.iam.eks_node_group_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    mapUsers = yamlencode(concat([
      {
        userarn  = data.aws_caller_identity.current.arn
        username = "admin-user"
        groups   = ["system:masters"]
      }
    ], var.map_users))
  }
}

# Ingress Controller
resource "helm_release" "nginx_ingress" {
  depends_on = [kubernetes_config_map.aws_auth]

  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.8.3"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}
