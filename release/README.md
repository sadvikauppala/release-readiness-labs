# OrderFlow v2.3.0 Release Runbook

## Release identity

- Application: OrderFlow
- Semantic version: `2.3.0`
- Immutable source tag: `v2.3.0`
- Container tag: `v2.3.0-<full-git-commit-sha>`
- Target: private Azure Kubernetes Service (AKS), namespace `orderflow-production`
- Image registry: Azure Container Registry (ACR)
- Deployment strategy: rolling update (zero unavailable replicas), readiness/liveness probes, 3 replicas, and a PodDisruptionBudget
- Approval: required through the protected GitHub `production` environment

The Git release tag identifies an exact source commit. The full commit SHA is part of the image tag, and the build digest is printed in the successful production job summary. Do not move or reuse a release tag or overwrite an artifact tag.

## Platform bootstrap (not part of an application deployment)

1. Configure encrypted, access-controlled remote Terraform state with locking before running Terraform. Authenticate the operator to Azure through the approved identity flow; do not put Azure credentials in `.tfvars` or source control.
2. Apply `deployment/terraform` with the approved resource group, region, globally unique AKS/ACR names, and a minimum three-node production pool. The first apply creates the private cluster and registry without assigning GitHub deployment permissions.
3. From an authorized network, use a platform administrator to apply `deployment/kubernetes/namespace.yaml` once.
4. Re-apply Terraform with `github_deploy_identity_object_id` and `github_image_publisher_identity_object_id` set to the distinct federated identities. Terraform grants `AcrPush` only to the publisher and AKS RBAC Writer only to the deployer. AKS kubelet identity receives `AcrPull`.
5. Configure a hardened self-hosted Linux runner with labels `self-hosted`, `linux`, `x64`, and `orderflow-production`; give it private network access to AKS and Azure CLI. The image publisher runs on a GitHub-hosted runner and has no cluster access. Configure Azure federated credentials for the protected release tag (publisher) and this repository's `production` GitHub Environment subject (deployer).
6. Configure repository-level GitHub Actions variables `AZURE_IMAGE_PUBLISHER_CLIENT_ID`, `AZURE_DEPLOY_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`, and `AZURE_ACR_NAME`. Configure required independent environment reviewers and deployment branch/tag restrictions in GitHub settings. Leave `PRODUCTION_RELEASE_ENABLED` unset until sign-off. Do not add a client secret or kubeconfig.
7. Provision and verify ingress, TLS certificates, DNS, monitoring, alerting, network policy, and backup/incident contacts through the platform process. The included Service is internal `ClusterIP`; it intentionally does not expose unauthenticated public HTTP.

## Release and approval sequence

1. Complete review of code, Terraform plan, Kubernetes manifests, security findings, change window, rollback target, and all pending entries in `approvals.yml`.
2. Push the reviewed changes to a protected branch or pull request. The `OrderFlow Release Pipeline` runs locked-dependency installation, real HTTP endpoint tests, and release metadata/target assertions. This validation workflow does not deploy.
3. Before release, confirm `app/package.json` and `release.json` are exactly `2.3.0`; protect the `v2.3.0` Git tag against deletion and force updates. The pipeline rejects any tag that does not match the app version.
4. Create and push `v2.3.0` only after approvals. The tagged workflow validates, builds and publishes the immutable ACR image using the release tag plus full source SHA, then records the image digest.
5. The deployment job requires successful validation and image publication, the default-off `PRODUCTION_RELEASE_ENABLED=true` switch, and GitHub environment reviewer approval before Azure authentication or cluster access.
6. The deployment waits for rollout completion and calls `/health` from a pod. The on-call engineer additionally verifies ingress/TLS, external `/health`, order flows, error rate, latency, and alerts. Record the exact source SHA, Actions run, image tag/digest, approver, and validation result in `release-summary.yml` and the change record.

## Rollback

Initiate rollback if readiness/liveness checks fail, critical order flows fail, or agreed production SLOs are breached. Stop further promotion, notify the incident commander and approver, and capture the deployed revision, image digest, and symptoms. Run `scripts/rollback.sh` from a trusted operator session, or use the command recorded in `rollback.yml`. Wait for the previous Deployment revision to become ready; validate `/health`, order flows, metrics, and alerts. If that revision cannot be restored, route traffic away from the service and follow the incident plan. Record the outcome and schedule a post-incident review. There is no database migration in this candidate, so no data rollback is currently required.

## Readiness status

This repository is a **release candidate, not an authorization to deploy**. The checklist, protected GitHub environment, Azure federated identity, private runner/network path, provisioned infrastructure, external ingress/TLS, successful GitHub validation run, approval, and image digest evidence must all be completed before production promotion. A green branch validation run is not a production deployment.
