```markdown
# Security Measures (starter checklist & secrets)

Repository & CI
- Require branch protection + required status checks (CI and security).
- Enable Dependabot and configure version updates.
- Add CodeQL scanning (enable via Actions) and a tfsec/tflint job for Terraform.

Secrets
- Use GitHub Actions Secrets for STAGING_SSH, DOCKERHUB_TOKEN, TF_BACKEND_CREDS, OIDC where possible.
- Never store secrets in code. Use pre-commit secret scanning.

IaC & Runtime
- Run `terraform fmt`/`terraform validate` and `tfsec` in CI.
- Run image scanning (Trivy) in CI for container images.

Monitoring & Response
- Define SLOs and tie alerts to error budgets.
- Use low-noise alerting, route to on-call, and keep runbooks close to alerts.

Contact for security & offers:
- katdevops099@gmail.com
```