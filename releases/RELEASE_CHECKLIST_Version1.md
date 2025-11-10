```markdown
# Release Checklist (Quick Guardrails)

Purpose: ensure every release follows the same safety steps and can be rolled back quickly.

Pre-merge
- [ ] PR includes description, risk level, rollback plan
- [ ] Unit tests pass
- [ ] Lint + format pass
- [ ] Dependency and security scans pass (Dependabot / CodeQL / Snyk/Trivy)
- [ ] Infrastructure changes have Terraform plan attached

Pre-deploy (staging)
- [ ] Deploy to staging succeeded
- [ ] Smoke tests (health endpoints) passed
- [ ] Basic E2E tests passed
- [ ] Observability: required dashboards updated for feature metrics

Production deploy
- [ ] Canary/Blue-Green strategy configured OR feature flag enabled for limited users
- [ ] Post-deploy health checks pass (automated)
- [ ] No critical alerts for 15–30 minutes (configurable)
- [ ] If any critical failure: trigger rollback and notify incident channel

Post-deploy
- [ ] Update release notes and tag
- [ ] Monitor metrics for 24–72 hours
- [ ] If incident occurred: create postmortem using the template
```