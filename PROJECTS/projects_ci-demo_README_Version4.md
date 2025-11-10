```markdown
# CI Demo

This demo shows a minimal GitHub Actions pipeline that:
- checks out code
- runs lint/tests
- builds a Docker image (optional)
- deploys to a staging endpoint (scripted/mocked)

Files:
- .github/workflows/ci.yml  (main pipeline)
- scripts/deploy/deploy-staging.sh

How to demo locally:
1. Fork this repo.
2. Enable GitHub Actions.
3. Create Secrets (see docs/Security-Measures.md for names).
4. Open a PR to see the pipeline run.

Notes:
- Use this as the base to add language-specific steps and real deployment targets.
```