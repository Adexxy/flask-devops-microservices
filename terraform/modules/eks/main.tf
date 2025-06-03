# Module: `modules/eks/main.tf`

data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "microservices_cluster" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.33"

  vpc_config {
    subnet_ids = var.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

  tags = {
    Name        = "eks-cluster-${var.cluster_name}"
    Environment = var.environment
  }
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# resource "kubernetes_config_map" "aws_auth" {
#   depends_on = [aws_eks_cluster.microservices_cluster]

#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapUsers = yamlencode(var.map_users)
#     mapRoles = yamlencode(var.map_roles)
#   }
# }

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [aws_eks_cluster.microservices_cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    # 1) map the “creator IAM principal” as bootstrap admin:
    mapUsers = yamlencode(
      [
        {
          userarn  = data.aws_caller_identity.current.arn
          username = "cluster-bootstrap"
          groups   = ["system:masters"]
        }
      ]
      # 2) then append any additional map_users passed in
    )

    # 3) map node‐group role(s) so EC2 nodes can join
    mapRoles = yamlencode(var.map_roles)
  }
}