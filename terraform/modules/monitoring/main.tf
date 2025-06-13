# modules/monitoring/main.tf
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  create_namespace = true
  version    = "25.8.0"

  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  version    = "7.3.1"

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
}

resource "kubernetes_manifest" "cluster_autoscaler" {
  manifest = yamldecode(templatefile("${path.module}/templates/cluster-autoscaler.yaml", {
    cluster_name = var.cluster_name
    region       = var.aws_region
    role_arn     = var.cluster_autoscaler_role_arn
  }))
}