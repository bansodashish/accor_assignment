# The Redemption - SRE Assessment

This repository contains an AWS EKS reference design for **The Redemption**, a business-critical microservice responsible for global hotel point deductions.

**Repository:** [github.com/bansodashish/accor_assignment](https://github.com/bansodashish/accor_assignment)

```bash
git clone https://github.com/bansodashish/accor_assignment.git
cd accor_assignment
```

## Deliverables

- `terraform/` — Modular Terraform infrastructure: root composition wires focused modules (network, eks, kms, secrets, dynamodb, sqs, iam, addons, vpc-endpoints, ecr, waf, dns).
- `k8s/base/` — Kubernetes base manifests shared across all environments.
- `k8s/overlays/{dev,staging,prod}/kustomization.yaml` — Single Kustomize overlay file per environment with all patches inlined (replicas, resources, WAF ARN, Secrets Manager path, Karpenter node role, HPA limits).
- `docs/archtitecture_diagram.drawio` — Source draw.io architecture diagram.
- `docs/architecture_diagram.png` — Exported architecture diagram image.
- `docs/redemption_sre_design.pdf` — Executive SRE assessment document (Executive Summary, Core Architectural Decisions, Scalability Strategy, Security and Networking, Reliability and Observability, Failure Recovery, Team Delegation Plan).

## Assumptions

- S3 state buckets (`redemption-{env}-tf-state`) and DynamoDB lock tables (`redemption-{env}-tf-lock`) are created before the first `terraform init`.
- The application image is published to ECR (IMMUTABLE tags enforced); image tag updates are delivered as Git changes to the overlay `kustomization.yaml`.
- External secrets are synchronised from AWS Secrets Manager through External Secrets Operator via IRSA.
- The redemption transaction path uses idempotency keys and conditional writes at the application/data layer.

## Deployment Model (Jenkins + Kustomize)

Kubernetes manifests are Kustomize-based (`k8s/base` + per-environment overlays). Jenkins is the deployment controller — it builds the final manifests with `kustomize build` and applies them directly with `kubectl apply`.

Pipeline flow per environment:

1. **Terraform** — `init → plan → apply` (gated by `DEPLOY_TARGET`).
2. **Kustomize Diff** — `kustomize build k8s/overlays/<env> | kubectl diff -f -` (non-blocking, shows what will change).
3. **Deploy App** — `kustomize build k8s/overlays/<env> | kubectl apply -f -` followed by `kubectl rollout status`.

On failure the pipeline prints the rollback command: `kubectl rollout undo deployment/redemption-api -n redemption`.

## Quick Start

```bash
# One-time: create S3 state bucket and DynamoDB lock table for the target env, then:
cd terraform
terraform init -backend-config=envs/dev/backend.hcl
terraform plan -var-file=envs/dev/terraform.tfvars
terraform apply -var-file=envs/dev/terraform.tfvars
```

```bash
# Preview what Kustomize will apply for dev
kustomize build k8s/overlays/dev | kubectl diff -f -

# Apply manually (Jenkins does this automatically)
kustomize build k8s/overlays/dev | kubectl apply -f -
kubectl rollout status deployment/redemption-api -n redemption --timeout=300s
```

## WAF ARN In Overlays

WAF ACL ARNs are stored directly in each environment overlay `kustomization.yaml`. When the Terraform-managed WAF changes, update the corresponding overlay file and commit that change so the next Jenkins pipeline applies it.

## Jenkins Requirements

- AWS credentials configured on Jenkins agents (for Terraform + kubectl).
- `kubectl` and `kustomize` installed on Jenkins agents and configured for the target cluster.
- Git push permission to the tracked branch when `AUTO_COMMIT_GITOPS_UPDATES=true` (auto-commits WAF ARN updates).
- Pipeline parameters: `ENVIRONMENT` (dev/staging/prod), `DEPLOY_TARGET` (infra-and-app/infra-only/app-only), `AUTO_APPROVE_TERRAFORM`, `AUTO_COMMIT_GITOPS_UPDATES`, `CLUSTER_NAME`, `AWS_REGION`.

## Assessment Assets

The repository currently stores the generated assessment artifacts directly under `docs/`:

- `docs/redemption_sre_design.pdf`
- `docs/architecture_diagram.png`
- `docs/archtitecture_diagram.drawio`

## Repository Layout

```text
.
├── .gitignore
├── Jenkinsfile                    # Declarative pipeline: Terraform + Kustomize + kubectl, per-env
├── README.md
├── docs
│   ├── architecture_diagram.png
│   ├── archtitecture_diagram.drawio
│   └── redemption_sre_design.pdf
├── k8s
│   ├── base                       # Shared manifests — source of truth for all envs
│   │   ├── clustersecretstore.yaml
│   │   ├── deployment.yaml
│   │   ├── externalsecret.yaml
│   │   ├── hpa.yaml
│   │   ├── ingress.yaml
│   │   ├── karpenter-nodepool.yaml
│   │   ├── kustomization.yaml
│   │   ├── kyverno-policy.yaml
│   │   ├── namespace.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── pdb.yaml
│   │   ├── prometheusrule.yaml
│   │   ├── service.yaml
│   │   ├── serviceaccount.yaml
│   │   └── servicemonitor.yaml
│   └── overlays
│       ├── dev                    # Single kustomization.yaml — all dev patches inlined
│       │   └── kustomization.yaml
│       ├── staging                # Single kustomization.yaml — all staging patches inlined
│       │   └── kustomization.yaml
│       └── prod                   # Single kustomization.yaml — all prod patches inlined
│           └── kustomization.yaml
└── terraform
    ├── backend.tf
    ├── envs
    │   ├── dev
    │   │   ├── backend.hcl        # S3 backend partial config for dev
    │   │   └── terraform.tfvars   # Dev-specific variable values
    │   ├── staging
    │   │   ├── backend.hcl
    │   │   └── terraform.tfvars
    │   └── prod
    │       ├── backend.hcl
    │       └── terraform.tfvars
    ├── main.tf                    # Root composition — wires all modules
    ├── outputs.tf
    ├── providers.tf
    ├── variables.tf
    ├── versions.tf
    └── modules
        ├── addons      # Helm: ALB controller, Karpenter, ESO, kube-prometheus-stack, Prometheus Adapter, Kyverno
        ├── dns
        ├── dynamodb    # Idempotency table with PITR and KMS encryption
        ├── ecr         # ECR repo — IMMUTABLE tags, KMS, scan-on-push, node pull policy
        ├── eks         # EKS cluster, node group, OIDC, etcd encryption, private endpoint
        ├── iam         # IRSA roles and least-privilege policies
        ├── kms         # Customer-managed KMS key with automatic rotation
        ├── network     # VPC, subnets, IGW, NAT gateways, route tables
        ├── secrets     # Secrets Manager secret
        ├── sqs         # Karpenter EC2 interruption queue
        ├── vpc-endpoints  # PrivateLink: ECR, STS, Secrets Manager (Interface); S3, DynamoDB (Gateway)
        └── waf         # Regional WAF Web ACL: SQLi protection, IP reputation, and rate limiting
```

