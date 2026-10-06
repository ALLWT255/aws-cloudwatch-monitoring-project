# Lessons Learned

- **Installed is not configured.** The initial EC2 user data installed the
  CloudWatch agent, but it was unconfigured and inactive until manual setup.
- **Use logs to explain symptoms.** The `/cloudwatch-lab-check` 404 was traced
  through CloudWatch to a missing file under `/usr/share/nginx/html`. Creating
  the file produced 200 in PowerShell and the access log.
- **Turn manual recovery into repeatable startup.** User data now writes the
  agent JSON, loads it, starts/enables services, and preserves group-based log
  access through rotation. The public route and IAM attachment are launch dependencies.
- **Test first boot on a fresh server.** Only EC2 was replaced. Cloud-init done,
  service status, agent configuration, and HTTP 200 verified the new bootstrap;
  CloudWatch received that server's access logs and NGINX startup notices.
- **Keep evidence tied to its instance.** The memory graph is from the original
  instance. It does not verify replacement-instance memory metrics or disk metrics.
  A configuration entry alone is not evidence of received telemetry.
- **Preserve template boundaries.** Terraform `file()` and a quoted shell heredoc
  preserve `${aws:...}` placeholders for the agent to resolve.
- **Separate CI from deployment.** GitHub Actions runs Terraform format, init,
  and validation checks. Deployment was local; CD remains pending.
- **Know the current limits.** The lab is HTTP and single-instance, with public
  SSH ingress. Dashboards and alarms are future work, not deployed features.

See the [README screenshots and chronology](../README.md) and
[runbook](runbook.md) for the evidence and repeatable verification steps.
