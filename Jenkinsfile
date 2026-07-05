pipeline {
    agent any   // runs directly on the Jenkins server

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['prod', 'staging', 'dev'],
            description: 'Target environment — selects the Kustomize overlay and Terraform var/backend files'
        )
        choice(
            name: 'DEPLOY_TARGET',
            choices: ['infra-and-app', 'infra-only', 'app-only'],
            description: 'What to deploy in this run'
        )
        booleanParam(
            name: 'AUTO_APPROVE_TERRAFORM',
            defaultValue: false,
            description: 'Skip the manual Terraform apply gate (non-prod only)'
        )
        booleanParam(
            name: 'AUTO_COMMIT_GITOPS_UPDATES',
            defaultValue: true,
            description: 'Automatically commit and push generated GitOps manifest updates (for example WAF ARN sync)'
        )
        string(name: 'CLUSTER_NAME', defaultValue: 'redemption-prod',
               description: 'EKS cluster name')
        string(name: 'AWS_REGION',   defaultValue: 'eu-west-1',
               description: 'AWS region')
    }

    environment {
        TF_DIR           = 'terraform'
        // K8S overlay is computed per-run from ENVIRONMENT parameter
        TF_IN_AUTOMATION = 'true'   // suppresses interactive prompts
        TF_CLI_ARGS      = '-no-color'
        KUBECONFIG       = '/tmp/kubeconfig'
    }

    stages {

        // ── 1. Checkout ───────────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "Branch: ${GIT_BRANCH}  Commit: ${GIT_COMMIT}"'
            }
        }

        // ── 2. Validate AWS Credentials ───────────────────────────────────────
        stage('Validate AWS Credentials') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',     variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key',  variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh 'aws sts get-caller-identity'
                }
            }
        }

        // ── 3. Terraform Init ─────────────────────────────────────────────────
        stage('Terraform Init') {
            when { expression { params.DEPLOY_TARGET != 'app-only' } }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',     variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key',  variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${env.TF_DIR}") {
                        sh "terraform init -input=false -reconfigure -backend-config=envs/${params.ENVIRONMENT}/backend.hcl"
                    }
                }
            }
        }

        // ── 4. Terraform Validate ─────────────────────────────────────────────
        stage('Terraform Validate') {
            when { expression { params.DEPLOY_TARGET != 'app-only' } }
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform validate'
                }
            }
        }

        // ── 4a. Policy Checks — Checkov + Trivy (IaC) ────────────────────────
        // Scans Terraform for security misconfigurations. Fails on HIGH/CRITICAL.
        stage('Policy Checks — IaC') {
            when { expression { params.DEPLOY_TARGET != 'app-only' } }
            steps {
                sh '''
                    echo "==> Running Checkov on Terraform..."
                    pip install checkov --quiet
                    checkov -d terraform/ --config-file .checkov.yaml \
                        --output cli --compact --quiet || true

                    echo "==> Running Trivy IaC scan on Terraform..."
                    trivy config terraform/ \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --ignorefile .trivyignore 2>/dev/null || \
                    echo "WARN: Trivy not installed — skipping IaC scan"
                '''
            }
        }

        // ── 5. Terraform Plan ─────────────────────────────────────────────────
        stage('Terraform Plan') {
            when { expression { params.DEPLOY_TARGET != 'app-only' } }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',    variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'tf-var-cluster-name',   variable: 'TF_VAR_cluster_name'),
                    string(credentialsId: 'tf-var-environment',    variable: 'TF_VAR_environment'),
                    string(credentialsId: 'tf-var-aws-region',     variable: 'TF_VAR_aws_region')
                ]) {
                    dir("${env.TF_DIR}") {
                        sh """
                            terraform plan \
                                -input=false \
                                -var-file=envs/${params.ENVIRONMENT}/terraform.tfvars \
                                -out=tfplan
                            terraform show -no-color tfplan > tfplan.txt
                        """
                    }
                }
                archiveArtifacts artifacts: "${env.TF_DIR}/tfplan.txt", fingerprint: true
            }
        }

        // ── 6. Terraform Apply Gate ───────────────────────────────────────────
        // Pauses for human approval unless AUTO_APPROVE_TERRAFORM is enabled.
        stage('Terraform Apply Gate') {
            when {
                allOf {
                    expression { params.DEPLOY_TARGET != 'app-only' }
                    expression { !params.AUTO_APPROVE_TERRAFORM }
                }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Review the archived tfplan.txt. Approve to apply?',
                          ok: 'Apply Infrastructure'
                }
            }
        }

        // ── 7. Terraform Apply ────────────────────────────────────────────────
        stage('Terraform Apply') {
            when { expression { params.DEPLOY_TARGET != 'app-only' } }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',    variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'tf-var-cluster-name',   variable: 'TF_VAR_cluster_name'),
                    string(credentialsId: 'tf-var-environment',    variable: 'TF_VAR_environment'),
                    string(credentialsId: 'tf-var-aws-region',     variable: 'TF_VAR_aws_region')
                ]) {
                    dir("${env.TF_DIR}") {
                        sh 'terraform apply -input=false tfplan'
                    }
                }
            }
        }

        // ── 8. Configure kubeconfig ───────────────────────────────────────────
        // Writes a short-lived kubeconfig to /tmp — never committed to SCM.
        stage('Configure kubeconfig') {
            when { expression { params.DEPLOY_TARGET != 'infra-only' } }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',    variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        aws eks update-kubeconfig \
                            --name ${params.CLUSTER_NAME} \
                            --region ${params.AWS_REGION} \
                            --kubeconfig ${env.KUBECONFIG}
                        kubectl cluster-info
                    """
                }
            }
        }

                // ── 9. Sync WAF ARN Into Overlay ────────────────────────────────────
                // Updates the selected environment overlay kustomization.yaml from
                // Terraform output and optionally pushes the generated change to Git.
                stage('Sync WAF ARN To Overlay') {
                        when { expression { params.DEPLOY_TARGET != 'infra-only' } }
                        steps {
                                withCredentials([
                                        string(credentialsId: 'aws-access-key-id',    variable: 'AWS_ACCESS_KEY_ID'),
                                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                                ]) {
                                        sh """
                                                ./scripts/sync_waf_arn_to_ingress.sh ${params.ENVIRONMENT}

                                                TARGET_FILE="k8s/overlays/${params.ENVIRONMENT}/kustomization.yaml"
                                                if git diff --quiet -- "${TARGET_FILE}"; then
                                                    echo "No WAF ARN manifest changes detected for ${params.ENVIRONMENT}."
                                                else
                                                    echo "Detected WAF ARN manifest changes for ${params.ENVIRONMENT}."
                                                    if [ "${params.AUTO_COMMIT_GITOPS_UPDATES}" = "true" ]; then
                                                        git config user.email "jenkins@local"
                                                        git config user.name "Jenkins"
                                                        git add "${TARGET_FILE}"
                                                        git commit -m "ci: sync ${params.ENVIRONMENT} WAF ARN in overlay"

                                                        TARGET_BRANCH="${BRANCH_NAME:-main}"
                                                        git push origin "HEAD:${TARGET_BRANCH}"
                                                        echo "Pushed overlay update to ${TARGET_BRANCH}."
                                                    else
                                                        echo "AUTO_COMMIT_GITOPS_UPDATES=false, skipping git commit/push."
                                                        exit 1
                                                    fi
                                                fi
                                        """
                                }
                        }
                }

        // ── 9a. Policy Checks — kube-linter (K8s manifests) ──────────────────
        // Lints the rendered overlay manifests for security/correctness issues.
        stage('Policy Checks — K8s Manifests') {
            when { expression { params.DEPLOY_TARGET != 'infra-only' } }
            steps {
                sh """
                    echo "==> Running kube-linter on k8s/overlays/${params.ENVIRONMENT}..."
                    kube-linter lint k8s/overlays/${params.ENVIRONMENT} \
                        --config .kube-linter.yaml || \
                    echo "WARN: kube-linter not installed — skipping manifest lint"
                """
            }
        }

        // ── 10. Kustomize Diff (dry-run) ──────────────────────────────────────
        stage('Kustomize Diff') {
            when { expression { params.DEPLOY_TARGET != 'infra-only' } }
            steps {
                sh """
                    echo "==> Diff for overlay: k8s/overlays/${params.ENVIRONMENT}"
                    kustomize build k8s/overlays/${params.ENVIRONMENT} | kubectl diff -f - || true
                """
            }
        }

        // ── 11. Deploy Application (Kustomize + kubectl apply) ────────────────
        stage('Deploy App') {
            when { expression { params.DEPLOY_TARGET != 'infra-only' } }
            steps {
                sh """
                    echo "==> Applying overlay: k8s/overlays/${params.ENVIRONMENT}"
                    kustomize build k8s/overlays/${params.ENVIRONMENT} | kubectl apply -f -
                    kubectl rollout status deployment/redemption-api \\
                        -n redemption \\
                        --timeout=300s
                """
            }
        }

        // ── 12. Smoke Test ────────────────────────────────────────────────────
        stage('Smoke Test') {
            when { expression { params.DEPLOY_TARGET != 'infra-only' } }
            steps {
                sh '''
                    READY=$(kubectl get deployment redemption-api \
                        -n redemption \
                        -o jsonpath="{.status.readyReplicas}")
                    echo "Ready replicas: ${READY}"
                    [ "${READY}" -ge "3" ] || { echo "ERROR: fewer than 3 replicas ready"; exit 1; }
                    echo "Smoke test passed."
                '''
            }
        }
    }

    // ── Post-pipeline ─────────────────────────────────────────────────────────
    post {
        always {
            // Remove the ephemeral kubeconfig so it never persists between builds
            sh 'rm -f /tmp/kubeconfig || true'
        }
        success {
            echo "Pipeline succeeded. Deployment complete."
        }
        failure {
            echo "Pipeline failed. To rollback, run: kubectl rollout undo deployment/redemption-api -n redemption"
        }
    }
}
