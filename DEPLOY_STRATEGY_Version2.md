```markdown
## Deploy Strategy — recommended pattern

1. Branching
   - Use short-lived feature branches. Merge to main via PR once checks pass.
2. Staging
   - Any merge to main triggers staging pipeline (build -> run smoke tests -> deploy to staging).
3. Production
   - Protected production branch or tag release flow.
   - Production deploys require:
     - Manual approval step if change is high-risk OR
     - Automated canary with metric checks
4. Rollback
   - Keep quick rollback steps in the PR and release notes.
   - Automated rollback if post-deploy health checks fail.
5. Feature flags
   - Use a simple flags file or a feature-flag provider; prefer server-side flags for big changes.
```