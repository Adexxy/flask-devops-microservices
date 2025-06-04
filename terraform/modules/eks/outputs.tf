output "cluster_name" {
  value = aws_eks_cluster.microservices_cluster.name
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.microservices_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.microservices_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.microservices_cluster.certificate_authority[0].data
}
