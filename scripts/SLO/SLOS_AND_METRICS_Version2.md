```markdown
# SLOs & Metrics (starter examples)

Goal: use SLOs to inform deploy friendliness and alerting.

Example SLOs
- Availability: 99.9% for frontend critical path (error budget 0.1%)
- API latency: 95th percentile < 300ms
- Deployment success: 90% of production deploys without rollback

Metrics to collect
- Deployment success/failure events
- Error rate and request latency
- Alert counts by type and severity
- MTTR per incident
Use these to gate deploys and to tune alerting thresholds.
```