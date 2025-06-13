# # Module: `modules/eks/main.tf`

resource "aws_eks_cluster" "microservices_cluster" {
  name     = var.cluster_name
  version  = "1.29"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [var.cluster_security_group_id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Name        = "eks-cluster-${var.cluster_name}"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy
  ]
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      [{
        rolearn  = var.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }],
      var.map_roles
    ))
    mapUsers = yamlencode(var.map_users)
  }

  depends_on = [aws_eks_cluster.microservices_cluster]
}

# Addon: CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.microservices_cluster.name
  addon_name        = "coredns"
  addon_version     = "v1.10.1-eksbuild.6"
  resolve_conflicts = "OVERWRITE"
  depends_on = [
    module.node_group
  ]
}

# Addon: kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.microservices_cluster.name
  addon_name        = "kube-proxy"
  addon_version     = "v1.29.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
}

# Addon: VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.microservices_cluster.name
  addon_name        = "vpc-cni"
  addon_version     = "v1.16.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.microservices_cluster.name
}






# data "aws_caller_identity" "current" {}

# resource "aws_eks_cluster" "microservices_cluster" {
#   name     = var.cluster_name
#   version  = "1.29" # Updated to current stable version
#   role_arn = aws_iam_role.cluster.arn

#   vpc_config {
#     subnet_ids              = var.private_subnets
#     endpoint_private_access = true
#     endpoint_public_access  = true
#     public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
#     security_group_ids      = [var.cluster_security_group_id]
#   }

#   enabled_cluster_log_types = ["api", "audit", "authenticator"]

#   tags = {
#     Name        = "eks-cluster-${var.cluster_name}"
#     Environment = var.environment
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
#   ]
# }


# # ───────────────────────────────────────────
# # modules/eks/main.tf (add at top after aws_eks_cluster)
# # ───────────────────────────────────────────

# # Let this module create a data source to fetch its own auth token:
# data "aws_eks_cluster_auth" "this" {
#   name = aws_eks_cluster.microservices_cluster.name
# }

# # In‐module Kubernetes provider: points at the EKS cluster resource just created
# # provider "kubernetes" {
# #   host                   = aws_eks_cluster.microservices_cluster.endpoint
# #   cluster_ca_certificate = base64decode(aws_eks_cluster.microservices_cluster.certificate_authority[0].data)
# #   token                  = data.aws_eks_cluster_auth.this.token
# # }

# # # If you are also installing nginx‐ingress with Helm inside this module:
# # provider "helm" {
# #   kubernetes {
# #     host                   = aws_eks_cluster.microservices_cluster.endpoint
# #     cluster_ca_certificate = base64decode(aws_eks_cluster.microservices_cluster.certificate_authority[0].data)
# #     token                  = data.aws_eks_cluster_auth.this.token
# #   }
# # }

# resource "aws_iam_role" "cluster" {
#   name = "eks-cluster-${var.cluster_name}"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sts:AssumeRole",
#           "sts:TagSession"
#         ]
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.cluster.name
# }

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode(concat(
#       [{
#         rolearn  = module.iam.eks_node_group_role_arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:bootstrappers", "system:nodes"]
#       }],
#       var.map_roles
#     ))
#     mapUsers = yamlencode(var.map_users)
#   }
# }

# # resource "helm_release" "nginx_ingress" {
# #   name       = "ingress-nginx"
# #   repository = "https://kubernetes.github.io/ingress-nginx"
# #   chart      = "ingress-nginx"
# #   namespace  = "ingress-nginx"
# #   create_namespace = true

# #   set {
# #     name  = "controller.service.type"
# #     value = "LoadBalancer"
# #   }
# # }

