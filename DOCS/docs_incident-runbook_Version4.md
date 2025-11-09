```markdown
# Incident Runbook (Example)

Scope: high-severity incidents affecting production availability.

Steps:
1. Triage
   - Identify impacted services & customers.
   - Assign incident lead & scribe.
2. Containment
   - Rollback or failover to staging.
   - Disable problematic feature flags.
3. Mitigation
   - Apply hotfix or scale resources.
4. Post-incident
   - Create postmortem in `docs/postmortem-template.md`
   - Track follow-ups as issues and assign owners.

Escalation:
- On-call -> Team Lead -> Ops Manager -> CTO

Communication:
- Use #incident Slack channel and status page updates.

Contact for repo & offers:
- katdevops099@gmail.com
```