```markdown
# SOW — Secrets Health Check (SaaS-focused)

SOW ID: SOW-SHC-[YYYYMMDD]  
Client: [Client Name]  
Provider: KatXO / gamecentral720-collab  
Contact: katdevops099@gmail.com

Overview
Quick, focused audit of secrets usage in code, CI, IaC, and cloud configuration for a SaaS product. Provide remediation guidance and a short automation to detect leaked secrets.

Deliverables
- Secrets inventory and exposure report (code, repos, CI logs, IaC)
- Proof-of-exposure examples (redacted) and risk categorization
- Remediation plan and prioritized remediation PRs or patches (where safe)
- Automation script (pre-commit or CI job) to detect new secrets (example using detect-secrets or trufflehog)
- 30-minute remediation walkthrough

Timeline
- 1–2 business days from SOW acceptance and access provided

Assumptions & Client Responsibilities
- Client provides access to repos or allows scanning of public commits and specified private repos via provided credentials.
- Provider will not exfiltrate secrets; all findings will be redacted in reports.

Fees & Payment
- Fixed Fee: CAD 850
- Payment: 50% deposit recommended; 100% upfront acceptable for very small clients.

Acceptance Criteria
- Inventory delivered with remediation PRs or sample patches
- Monitoring rule (pre-commit or CI job) added to the repo and tested in a sample run

Optional Add-ons
- Secret rotation assistance and ephemeral credential setup (additional SOW)
- Vault setup and OIDC integration (additional SOW)

Sign-off
Client Representative: ___________________  Date: _______  
Provider: KatXO / gamecentral720-collab  Date: _______
```