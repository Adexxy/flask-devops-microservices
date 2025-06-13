# # This module creates IAM roles and policies for EKS cluster and node groups
# # and configures the aws-auth ConfigMap to allow access to the EKS cluster.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_oidc_role" {
  name = var.cluster_name != "" ? "github-oidc-${var.cluster_name}-${var.environment}" : var.github_oidc_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = var.github_oidc_sub
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "github_oidc_restricted" {
  name = "github-oidc-restricted-${var.environment}"
  role = aws_iam_role.github_oidc_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "eks_node_group_role" {
  name = var.cluster_name != "" ? "eks-node-group-${var.cluster_name}-${var.environment}" : "eks-node-group-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [name]
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster-autoscaler-${var.cluster_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "cluster-autoscaler-${var.cluster_name}-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}








# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   # thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
# }

# locals {
#   node_group_role_name = var.cluster_name != "" ? "eks-node-group-role-${var.cluster_name}-${var.environment}" : "eks-node-group-role-${var.environment}"
#   oidc_role_name       = var.cluster_name != "" ? "github-oidc-${var.cluster_name}" : var.github_oidc_role_name
# }

# resource "aws_iam_role" "github_oidc_role" {
#   # name = var.github_oidc_role_name
#   name = local.oidc_role_name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.github.arn
#       },
#       Action = "sts:AssumeRoleWithWebIdentity",
#       Condition = {
#         StringLike = {
#           "token.actions.githubusercontent.com:sub" = var.github_oidc_sub
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_admin" {
#   role       = aws_iam_role.github_oidc_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role_policy_attachment" "ecr_power_user" {
#   role       = aws_iam_role.github_oidc_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
# }


# resource "aws_iam_role" "eks_node_group_role" {
#   # name = "eks-node-group-role-${var.environment}"
#   name = local.node_group_role_name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
  
#   tags = {
#     Name        = "eks-node-group-role-${var.environment}"
#     Environment = var.environment
#   }
# }

# # Required for node group functionality
# resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
#   role       = aws_iam_role.eks_node_group_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# # Required for networking (CNI plugin)
# resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
#   role       = aws_iam_role.eks_node_group_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# # Required to pull container images from ECR
# resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
#   role       = aws_iam_role.eks_node_group_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_role_policy" "github_oidc_restricted" {
#   name = "github-oidc-restricted"
#   role = aws_iam_role.github_oidc_role.name

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:GetRepositoryPolicy",
#           "ecr:DescribeRepositories",
#           "ecr:ListImages",
#           "ecr:DescribeImages",
#           "ecr:BatchGetImage",
#           "ecr:InitiateLayerUpload",
#           "ecr:UploadLayerPart",
#           "ecr:CompleteLayerUpload",
#           "ecr:PutImage"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
