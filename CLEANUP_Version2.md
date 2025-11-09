```markdown
# Weekend Cleanup Checklist (priority order)

Goals: polish portfolio for Monday market push — readable, actionable, and sale-ready.

Quick wins
- [ X] Update GitHub profile picture and bio (short, friendly, contact email visible)
- [ X] Set repo visibility and confirm License: BSD-3-Clause at /LICENSE
- [ X] Add top-level TL;DR to README (1–2 lines plus contact)

Repo hygiene
- [ X] Add docs/services.md with three SOWs (Emergency CI, Secrets Health Check, 30-day retainer)
- [ ] Confirm .github/CODEOWNERS and .github/PULL_REQUEST_TEMPLATE.md are present
- [ ] Ensure .github/workflows/ci.yml exists and is sensible for demo

Demo content (one complete demonstration)
- [ ] CI Demo: PR -> main runs and passes (or simulated)
- [ ] Deploy script: scripts/deploy/deploy-staging.sh present and documented
- [ ] Terraform: infra/terraform with main.tf + variables + README (terraform fmt/validate)

Sales & outreach
- [] Add docs/recruiter-pitch.md and docs/services.md
- [ ] Create one-page PDF sell-sheet for outreach (copy from docs/services.md)
- [ ] Prepare 8 outreach messages (LinkedIn/email templates)

Product/operations
- [ ] Create onboarding issues and a "30-day on-ramp" milestone
- [ ] Add invoice template and SOW templates to /docs or /templates
- [ ] Add a small postmortem example in docs/postmortem-example.md

Polish & final checks
- [ ] Run a spellcheck (reinstall Grammarly if needed)
- [ ] Commit with clear messages and open a draft PR from portfolio-setup -> main
- [ ] Publish announcement/post (LinkedIn + Upwork listing) Monday morning
```