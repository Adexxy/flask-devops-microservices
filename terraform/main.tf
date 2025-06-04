# Root main.tf to pull all modules together

data "aws_caller_identity" "current" {}

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
  source      = "./modules/iam"
  environment = var.environment
  account_id  = var.account_id
  github_org  = var.github_org
  cluster_name = var.cluster_name
  repo_name   = var.repo_name
  github_branch = var.github_branch
}

module "eks" {
  source         = "./modules/eks"
  subnet_ids     = module.vpc.private_subnet_ids
  vpc_id         = module.vpc.vpc_id
  cluster_name   = var.cluster_name
  azs            = var.azs
  private_subnets = module.vpc.private_subnet_ids 
  environment    = var.environment 

  map_users = [
    {
      userarn = "arn:aws:iam::${var.aws_user_id}:user/${var.aws_user}"
      username = "github-actions"
      groups   = ["system:masters"]
    }
  ]
  map_roles = [
    {
      rolearn  = module.iam.eks_node_group_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]
}

module "rds" {
  source         = "./modules/rds"
  db_name        = var.db_name
  db_user        = var.db_username
  db_password    = var.db_password
  subnet_ids     = module.vpc.private_subnet_ids
  security_groups = [module.vpc.private_sg_id]
  environment    = var.environment
}

# module "s3" {
#   source      = "./modules/s3"
#   bucket-name = var.s3_bucket_name
# }

module "ecr" {
  source        = "./modules/ecr"
  service_names = var.ecr_service_names
  environment   = var.environment
}

module "node_group" {
  source            = "./modules/node_group"
  cluster_name      = var.cluster_name
  node_group_name   = "${var.environment}-node-group"
  subnet_ids        = module.vpc.private_subnet_ids
  node_role_arn     = module.iam.eks_node_group_role_arn
  instance_types    = ["t3.medium"]      # or your preferred type
  desired_capacity  = 2
  min_size          = 1
  max_size          = 3
  environment       = var.environment

  depends_on = [kubernetes_config_map.aws_auth]
}

# ————————————————————————————————
# 1) Read the EKS cluster once module.eks is done
# ————————————————————————————————
data "aws_eks_cluster" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}


# # ————————————————————————————————
# # 2) Configure the Kubernetes provider from the data source
# # ————————————————————————————————
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.eks.certificate_authority[0].data
    )
    token = data.aws_eks_cluster_auth.eks.token
  }
}

# ————————————————————————————————
# 3) Only now that Kubernetes is configured, fetch the Ingress Service
# ————————————————————————————————
# data "kubernetes_service" "nginx_ingress_lb" {
#   depends_on = [module.eks] # makes sure the cluster + helm release exist
#   metadata {
#     name      = "ingress-nginx-controller"
#     namespace = "ingress-nginx"
#   }
# }

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [module.eks]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = data.aws_caller_identity.current.arn
        username = "cluster-bootstrap"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::${var.aws_user_id}:user/${var.aws_user}"
        username = "github-actions"
        groups   = ["system:masters"]
      }
    ])
    mapRoles = yamlencode(var.map_roles)
  }
}

resource "helm_release" "nginx_ingress" {
  depends_on = [kubernetes_config_map.aws_auth]

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true
  version    = "4.0.19"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# ─────────────────────────────────────────────────────────────
# 4) Now fetch the AWS Load Balancer by tag—no Kubernetes API involved
# ─────────────────────────────────────────────────────────────

# data "aws_lb" "nginx_ingress" {
#   depends_on = [helm_release.nginx_ingress]

#   # Select the LB by the standard Kubernetes “service-name” tag:
#   tags = {
#     "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
#   }
# }
