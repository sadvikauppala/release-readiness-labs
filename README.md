# OrderFlow v2.3.0 — Release Readiness Candidate

This repository contains the OrderFlow release-readiness lab and the operational artifacts for its v2.3.0 production candidate. **No production deployment is performed by local validation.**

## Application and validation

The Node.js 22 application exposes `GET /` and `GET /health`. Install the locked dependencies with `npm ci --prefix app`, run endpoint tests with `npm test --prefix app`, and start locally with `npm start --prefix app`. Docker Compose is available for local-only testing with `docker compose up --build`.

The GitHub Actions workflow validates pushes to `main` and `investigation/**` branches and pull requests to `main`. A production deployment job can run only for the exact `v2.3.0` release tag, after validation, image publication, an explicit `PRODUCTION_RELEASE_ENABLED=true` switch, and approval in the protected `production` GitHub environment. The switch is intentionally unset by default.

## Production deployment decision

The release target is **Azure Kubernetes Service (AKS)** with **Azure Container Registry (ACR)**. This replaces the inconsistent AWS EC2 Terraform configuration. The release image is tagged `v2.3.0-<full-git-commit-sha>` and is deployed with a rolling update, health probes, resource limits, a PodDisruptionBudget, and a namespace-scoped service. The Kubernetes namespace is `orderflow-production`.

Terraform provisions the AKS/ACR baseline in `deployment/terraform`. Use an encrypted, access-controlled remote Terraform state backend with locking before any infrastructure provisioning; state files and credential files are ignored by Git. AKS is private, so the production GitHub Actions runner must be a hardened self-hosted Linux runner with network access to the cluster and the `orderflow-production` label.

## External prerequisites — release is not yet approved

Before a real tagged release can deploy, the repository/environment administrator must:

1. Configure GitHub environment `production` with required independent reviewers and restrict deployment to the protected `v*` tag policy.
2. Configure repository-level GitHub Actions variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`, and `AZURE_ACR_NAME`. These are identifiers, not credentials. Keep `PRODUCTION_RELEASE_ENABLED` unset until promotion is approved.
3. Configure Azure workload-identity federated credentials for the exact release tag used by image publication and for this repository's `production` GitHub Environment subject used by deployment. Grant only the required AKS namespace deployment and ACR push roles. Do not create a client secret.
4. Provision/verify the private runner, cluster network access, the `orderflow-production` namespace, AKS-to-ACR `AcrPull` role assignment, ingress/TLS/DNS, monitoring, and alerting.
5. Apply `deployment/kubernetes/namespace.yaml` through the platform bootstrap/admin process. The workflow identity should not have cluster-wide namespace-creation permissions.
6. Complete every item in `release/approvals.yml` and record the source commit, immutable image digest, and successful validation run in `release/release-summary.yml`.
7. Set the repository variable `PRODUCTION_RELEASE_ENABLED=true` only after reviewers, Azure identity, runner, network, cluster, and rollback readiness have been independently verified.

The checked-in summary intentionally remains **release-candidate / blocked** until those external controls and a successful validation run are evidenced. A branch validation run does not deploy the application.

## Operational release pack

- [Release metadata and artifact identity](release/release.json)
- [Production deployment configuration](release/deployment-config.yml)
- [Approval checklist](release/approvals.yml)
- [Rollback procedure](release/rollback.yml)
- [Validation and readiness summary](release/release-summary.yml)

The runbook in [release/README.md](release/README.md) contains the detailed release, approval, validation, and rollback sequence.

//Screenshot 1 — Initial Deployment Investigation
Capture the repository before making any fixes.

The screenshot should clearly show the failed deployment workflow or repository files containing release issues.

Caption (1 line): Describe the production risks discovered before beginning the investigation.

Screenshot 2 — Deployment Pipeline Repairs
Capture the updated deployment workflow after fixing the pipeline stages.

The screenshot should clearly show the corrected workflow configuration inside the editor.

Caption (1 line): Explain how the updated pipeline now supports a safer production deployment.

Screenshot 3 — Secure Release Configuration
Capture the repository after repairing deployment approvals, secret handling, release versioning, and infrastructure configuration.

The screenshot should clearly show the modified configuration files.

Caption (1 line): Explain how the repository now satisfies production deployment requirements.

Screenshot 4 — Successful Validation
Capture the successful GitHub Actions workflow execution after your fixes.

The completed workflow should finish successfully.

Caption (1 line): Explain why the release is now considered deployment-ready.

Screenshot 5 — Final Release Readiness Pack
Capture the completed release documentation together with the final repository state.

The screenshot should clearly show:

release documentation
rollback plan
deployment checklist
release version
Caption (1 line): Summarize why the release can now safely move to production.
