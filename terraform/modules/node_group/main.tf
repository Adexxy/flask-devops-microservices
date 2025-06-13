resource "aws_eks_node_group" "microservices_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_size
    max_size     = var.max_size
  }

  instance_types = var.instance_types

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  labels = {
    "nodegroup"    = var.node_group_name
    "environment"  = var.environment
  }

  taint {
    key    = "dedicated"
    value  = var.node_group_name
    effect = "NO_SCHEDULE"
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Environment = var.environment
  }
}
