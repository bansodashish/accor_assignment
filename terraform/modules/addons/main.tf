resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "3.4.0"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.8.1"
  namespace        = "karpenter"
  create_namespace = true

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.interruptionQueue"
    value = var.sqs_queue_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.karpenter_role_arn
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.17.0"
  namespace        = "external-secrets"
  create_namespace = true

  depends_on = [helm_release.aws_load_balancer_controller]
}

# ---------------------------------------------------------------------------
# Kyverno — admission controller that enforces image provenance policies.
# Blocks unsigned images, disallows 'latest' tag, and restricts the registry
# to the approved ECR account so no untrusted images can run in the cluster.
# ---------------------------------------------------------------------------
resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno"
  chart            = "kyverno"
  version          = "3.8.1"
  namespace        = "kyverno"
  create_namespace = true

  depends_on = [helm_release.aws_load_balancer_controller]

  set {
    name  = "replicaCount"
    value = "3"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "87.5.1"
  namespace        = "observability"
  create_namespace = true
  timeout          = 600

  depends_on = [helm_release.aws_load_balancer_controller]

  values = [yamlencode({
    grafana = {
      enabled = true
    }
    prometheus = {
      prometheusSpec = {
        retention = "15d"
        # Discover ServiceMonitor and PrometheusRule objects from all namespaces
        serviceMonitorSelectorNilUsesHelmValues = false
        ruleSelectorNilUsesHelmValues           = false
      }
    }
  })]
}

# ---------------------------------------------------------------------------
# Prometheus Adapter — bridges Prometheus metrics to the Kubernetes custom
# metrics API, enabling HPA to scale on RPS and latency (not only CPU/mem).
# ---------------------------------------------------------------------------
resource "helm_release" "prometheus_adapter" {
  name             = "prometheus-adapter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-adapter"
  version          = "5.3.0"
  namespace        = "observability"
  create_namespace = false

  depends_on = [helm_release.kube_prometheus_stack]

  values = [yamlencode({
    prometheus = {
      url  = "http://kube-prometheus-stack-prometheus.observability.svc"
      port = 9090
    }
    rules = {
      custom = [
        {
          # Exposes per-pod RPS as "http_requests_per_second" to the K8s custom metrics API
          seriesQuery = "http_requests_total{namespace=\"redemption\"}"
          resources = {
            overrides = {
              namespace = { resource = "namespace" }
              pod       = { resource = "pod" }
            }
          }
          name = {
            matches = "http_requests_total"
            as      = "http_requests_per_second"
          }
          metricsQuery = "sum(rate(http_requests_total{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)"
        }
      ]
    }
  })]
}
