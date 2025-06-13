# modules/network-policies/main.tf
resource "helm_release" "calico" {
  name       = "calico"
  repository = "https://projectcalico.docs.tigera.io/charts"
  chart      = "tigera-operator"
  namespace  = "tigera-operator"
  create_namespace = true
  version    = "v3.26.1"
}

resource "kubernetes_network_policy" "default_deny" {
  metadata {
    name      = "default-deny"
    namespace = "default"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}