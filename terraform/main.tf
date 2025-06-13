# # Root main.tf to pull all modules together

# Root main.tf - Complete solution with circular dependency resolution

data "aws_caller_identity" "current" {}

# Phase 1: Create all non-cluster-dependent infrastructure first
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

# Phase 2: Initial IAM roles with minimal permissions (no cluster name dependency)
module "iam_initial" {
  source               = "./modules/iam"
  environment          = var.environment
  account_id           = var.account_id
  github_org           = var.github_org
  repo_name            = var.repo_name
  github_branch        = var.github_branch
  github_oidc_role_name = var.github_oidc_role_name
  github_oidc_sub      = var.github_oidc_sub
  
  # Don't pass cluster_name initially
  # This creates roles with generic names
}

# Phase 3: Create EKS cluster using initial IAM roles
module "eks" {
  source         = "./modules/eks"
  # subnet_ids     = module.vpc.private_subnet_ids
  vpc_id         = module.vpc.vpc_id
  cluster_name   = var.cluster_name
  azs            = var.azs
  private_subnets = module.vpc.private_subnet_ids 
  cluster_security_group_id = module.vpc.cluster_security_group_id
  environment    = var.environment
  
  # Use initial IAM roles
  node_role_arn  = module.iam_initial.eks_node_group_role_arn
  
  # Basic mapUsers/mapRoles for initial access
  map_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      username = "cluster-admin"
      groups   = ["system:masters"]
    }
  ]
  
  map_roles = [
    {
      rolearn  = module.iam_initial.eks_node_group_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  depends_on = [module.iam_initial, module.vpc]
}

# Phase 4: Update IAM with cluster-specific configurations
module "iam_final" {
  source               = "./modules/iam"
  environment          = var.environment
  account_id           = var.account_id
  github_org           = var.github_org
  repo_name            = var.repo_name
  github_branch        = var.github_branch
  github_oidc_role_name = var.github_oidc_role_name
  github_oidc_sub      = var.github_oidc_sub
  cluster_name         = module.eks.cluster_name  # Now we have the cluster name
  
  # This will update the roles with cluster-specific names and permissions
  depends_on = [module.eks]
}

# Phase 5: Create node groups with final IAM roles
module "node_group" {
  source            = "./modules/node_group"
  cluster_name      = module.eks.cluster_name
  node_group_name   = "${var.environment}-node-group"
  subnet_ids        = module.vpc.private_subnet_ids
  node_role_arn     = module.iam_final.eks_node_group_role_arn
  instance_types    = var.node_instance_types
  desired_capacity  = var.node_desired_capacity
  min_size          = var.node_min_size
  max_size          = var.node_max_size
  environment       = var.environment
  taints            = var.node_taints

  depends_on = [
    module.iam_final,
    module.eks,
    kubernetes_config_map.aws_auth
  ]
}

# Phase 6: Monitoring and other cluster-dependent components
module "monitoring" {
  source                   = "./modules/monitoring"
  cluster_name             = module.eks.cluster_name
  aws_region              = var.aws_region
  cluster_autoscaler_role_arn = module.iam_final.eks_node_group_role_arn
  grafana_admin_password   = var.grafana_admin_password
  
  depends_on = [
    module.eks,
    module.node_group
  ]
}

module "network_policies" {
  source     = "./modules/network-policies"
  depends_on = [module.eks, module.node_group]
}

# Phase 7: Cluster services and workloads
module "ecr" {
  source        = "./modules/ecr"
  service_names = var.ecr_service_names
  environment   = var.environment
}

module "rds" {
  source         = "./modules/rds"
  db_name        = var.db_name
  db_user        = var.db_username
  db_password    = var.db_password
  subnet_ids     = module.vpc.private_subnet_ids
  security_groups = [module.vpc.private_sg_id]
  alarm_actions = var.alarm_actions
  environment    = var.environment
  
  depends_on = [module.vpc]
}

# Kubernetes provider configuration - single source in root module
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

# Cluster services configuration
resource "helm_release" "nginx_ingress" {
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

  depends_on = [
    module.node_group,
    module.monitoring
  ]
}

# Final aws-auth configmap with all roles and users
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      [{
        rolearn  = module.iam_final.eks_node_group_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }],
      [{
        rolearn  = module.iam_final.github_oidc_role_arn
        username = "github-actions"
        groups   = ["system:masters"] # Should be more restrictive in production
      }],
      var.map_roles
    ))
    mapUsers = yamlencode(concat(
      [{
        userarn  = "arn:aws:iam::${var.aws_user_id}:user/${var.aws_user}"
        username = "admin-user"
        groups   = ["system:masters"]
      }],
      var.map_users
    ))
  }

  depends_on = [module.eks]
}




# data "aws_caller_identity" "current" {}

# module "vpc" {
#   source                = "./modules/vpc"
#   name                  = var.vpc_name
#   vpc_name              = var.vpc_name
#   aws_region            = var.aws_region
#   azs                   = var.azs
#   vpc_cidr              = var.vpc_cidr
#   public_subnets        = var.public_subnets
#   private_subnets       = var.private_subnets
#   public_subnets_cidr   = var.public_subnets_cidr
#   private_subnets_cidr  = var.private_subnets_cidr
#   environment           = var.environment
# }

# # Phase 1: Initial IAM roles without cluster name
# module "iam_initial" {
#   source      = "./modules/iam"
#   environment = var.environment
#   account_id  = var.account_id
#   # Don't pass cluster_name initially
#   # Other required variables...
# }

# # Phase 2: Create EKS cluster
# module "eks" {
#   source         = "./modules/eks"
#   subnet_ids     = module.vpc.private_subnet_ids
#   vpc_id         = module.vpc.vpc_id
#   cluster_name   = var.cluster_name
#   node_role_arn  = module.iam_initial.eks_node_group_role_arn
#   # Other required variables...
#   depends_on     = [module.iam_initial]
# }

# # Phase 3: Update IAM with cluster details
# module "iam_final" {
#   source      = "./modules/iam"
#   environment = var.environment
#   account_id  = var.account_id
#   cluster_name = module.eks.cluster_name # Now we have the cluster name
#   # Other required variables...
#   depends_on  = [module.eks]
# }

# # Phase 4: Update node groups with final IAM roles
# module "node_group" {
#   source       = "./modules/node_group"
#   node_role_arn = module.iam_final.eks_node_group_role_arn
#   # Other required variables...
#   depends_on   = [module.iam_final, module.eks]
# }

# module "iam" {
#   source      = "./modules/iam"
#   environment = var.environment
#   account_id  = var.account_id
#   github_org  = var.github_org
#   cluster_name = var.cluster_name
#   repo_name   = var.repo_name
#   github_branch = var.github_branch
#   github_oidc_role_name = var.github_oidc_role_name
#   github_oidc_sub = var.github_oidc_sub
# }

# module "eks" {
#   source         = "./modules/eks"
#   subnet_ids     = module.vpc.private_subnet_ids
#   vpc_id         = module.vpc.vpc_id
#   cluster_name   = var.cluster_name
#   azs            = var.azs
#   private_subnets = module.vpc.private_subnet_ids 
#   cluster_security_group_id = module.vpc.private_sg_id
#   environment    = var.environment 

#   map_users = [
#     {
#       userarn = "arn:aws:iam::${var.aws_user_id}:user/${var.aws_user}"
#       username = "github-actions"
#       groups   = ["system:masters"]
#     }
#   ]
#   map_roles = [
#     {
#       rolearn  = module.iam.eks_node_group_role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups   = [
#         "system:bootstrappers",
#         "system:nodes"
#       ]
#     },
#   {
#     rolearn  = module.iam.github_oidc_role_arn
#     username = "github-actions"
#     groups   = ["system:masters"]
#   }
#   ]
# }

# module "rds" {
#   source         = "./modules/rds"
#   db_name        = var.db_name
#   db_user        = var.db_username
#   db_password    = var.db_password
#   subnet_ids     = module.vpc.private_subnet_ids
#   security_groups = [module.vpc.private_sg_id]
#   environment    = var.environment
# }

# # module "s3" {
# #   source      = "./modules/s3"
# #   bucket-name = var.s3_bucket_name
# # }

# module "ecr" {
#   source        = "./modules/ecr"
#   service_names = var.ecr_service_names
#   environment   = var.environment
# }

# module "node_group" {
#   source            = "./modules/node_group"
#   cluster_name      = var.cluster_name
#   node_group_name   = "${var.environment}-node-group"
#   subnet_ids        = module.vpc.private_subnet_ids
#   node_role_arn     = module.iam.eks_node_group_role_arn
#   instance_types    = ["t3.medium"]      # or your preferred type
#   desired_capacity  = 2
#   min_size          = 1
#   max_size          = 3
#   environment       = var.environment

#   depends_on = [kubernetes_config_map.aws_auth]
# }

# # ————————————————————————————————
# # 1) Read the EKS cluster once module.eks is done
# # ————————————————————————————————
# data "aws_eks_cluster" "eks" {
#   name       = module.eks.cluster_name
#   depends_on = [module.eks]
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = module.eks.cluster_name
# }


# # # ————————————————————————————————
# # # 2) Configure the Kubernetes provider from the data source
# # # ————————————————————————————————
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(
#       data.aws_eks_cluster.eks.certificate_authority[0].data
#     )
#     token = data.aws_eks_cluster_auth.eks.token
#   }
# }

# # ————————————————————————————————
# # 3) Only now that Kubernetes is configured, fetch the Ingress Service
# # ————————————————————————————————
# # data "kubernetes_service" "nginx_ingress_lb" {
# #   depends_on = [module.eks] # makes sure the cluster + helm release exist
# #   metadata {
# #     name      = "ingress-nginx-controller"
# #     namespace = "ingress-nginx"
# #   }
# # }

# # resource "kubernetes_config_map" "aws_auth" {
# #   depends_on = [module.eks]

# #   metadata {
# #     name      = "aws-auth"
# #     namespace = "kube-system"
# #   }

# #   data = {
# #     mapUsers = yamlencode([
# #       {
# #         userarn  = data.aws_caller_identity.current.arn
# #         username = "cluster-bootstrap"
# #         groups   = ["system:masters"]
# #       },
# #       {
# #         userarn  = "arn:aws:iam::${var.aws_user_id}:user/${var.aws_user}"
# #         username = "github-actions"
# #         groups   = ["system:masters"]
# #       }
# #     ])
# #     mapRoles = yamlencode(var.map_roles)
# #   }
# # }

# resource "helm_release" "nginx_ingress" {
#   depends_on = [kubernetes_config_map.aws_auth]

#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"
#   create_namespace = true
#   version    = "4.0.19"

#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }
# }

# # ─────────────────────────────────────────────────────────────
# # 4) Now fetch the AWS Load Balancer by tag—no Kubernetes API involved
# # ─────────────────────────────────────────────────────────────

# # data "aws_lb" "nginx_ingress" {
# #   depends_on = [helm_release.nginx_ingress]

# #   # Select the LB by the standard Kubernetes “service-name” tag:
# #   tags = {
# #     "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
# #   }
# # }

# module "monitoring" {
#   source = "./modules/monitoring"
#   cluster_name = module.eks.cluster_name
#   aws_region = var.aws_region
#   cluster_autoscaler_role_arn = module.iam.eks_node_group_role_arn
#   grafana_admin_password = var.grafana_admin_password
#   depends_on = [module.eks, module.node_group]
# }