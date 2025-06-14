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

  # Ensure proper ordering
  depends_on = [
    # aws_eks_cluster.microservices_cluster,
    # aws_eks_access_entry.default,
    var.cluster_arn
  ]
}