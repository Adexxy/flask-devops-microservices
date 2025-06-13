variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana"
}
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}
variable "aws_region" {
  type        = string
  description = "AWS region where the EKS cluster is deployed"
}
variable "cluster_autoscaler_role_arn" {
  type        = string
  description = "IAM role ARN for the cluster autoscaler"
}