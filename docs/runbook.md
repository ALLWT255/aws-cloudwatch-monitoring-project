# Operations Runbook

Run Terraform from the top-level project, not `cloudwatch-rebuild`. Deployments
were performed locally; GitHub Actions currently validates configuration only.

## Review and validate

```powershell
$env:AWS_PROFILE = "cloudwatch-deploy"
aws sts get-caller-identity
terraform fmt -check
terraform validate
terraform plan
terraform output -raw instance_id
terraform output -raw web_server_public_ip
```

Confirm the intended non-root identity before deployment. Do not print credential
process output or commit AWS configuration, state, private variables, or saved plans.
Review plans for replacements: the latest-AMI lookup can change the selected AMI.
User-data updates alone do not guarantee that first-boot scripts rerun.

## Fresh-server checks

Connect using your authorized EC2 access method and run each command separately:

```bash
sudo cloud-init status --wait
sudo systemctl is-enabled nginx amazon-cloudwatch-agent
sudo systemctl is-active nginx amazon-cloudwatch-agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
curl -I http://localhost/
sudo -u cwagent test -r /var/log/nginx/access.log
sudo -u cwagent test -r /var/log/nginx/error.log
sudo logrotate --debug /etc/logrotate.d/nginx
```

Expect cloud-init `done`, both services `enabled` and `active`, agent `running`
and `configured`, and HTTP 200. These startup/service/HTTP results were observed
on the replacement server; the readability and rotation commands remain useful
additional checks. See [the terminal evidence](screenshots/fresh-instance-bootstrap-service-checks.png).

Inspect `/var/log/cloud-init-output.log`, `journalctl -u nginx`, and
`/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log` if startup fails.

## CloudWatch checks

Select `us-east-1`. Open `access.log` and `error.log`, selecting the **current**
instance-ID stream rather than the terminated instance's stream. Fresh-instance
access events and NGINX startup notices in the error stream were verified.
An error-log file can contain normal notice-level messages.

In Metrics -> CWAgent, select the current InstanceId and look for recent
`mem_used_percent` and `disk_used_percent` samples. These are remaining verification
steps for the new instance; the published memory graph belongs to the original
instance and there is no disk-metric screenshot. Allow time for collection and
delivery. Confirm seven-day retention and STANDARD class on both log groups.

## Missing-file troubleshooting exercise

On the original instance, `/cloudwatch-lab-check` returned HTTP 404. CloudWatch
error logs showed `open()` failing for `/usr/share/nginx/html/cloudwatch-lab-check`.
After creating that file, PowerShell and CloudWatch access logs both confirmed 200.

To repeat intentionally on a lab instance where that file is absent:

```bash
curl -i http://localhost/cloudwatch-lab-check
printf 'CloudWatch lab check\n' | sudo tee /usr/share/nginx/html/cloudwatch-lab-check
curl -i http://localhost/cloudwatch-lab-check
```

From PowerShell in the project:

```powershell
$serverIp = terraform output -raw web_server_public_ip
curl.exe -i --max-time 10 "http://$serverIp/cloudwatch-lab-check"
```

Compare the timestamps and request path in both CloudWatch streams. This file is
a manual diagnostic artifact, not created by bootstrap, and is lost on replacement.
Screenshots record a historical IP; always obtain the current output before testing.

## Costs and cleanup

EC2, EBS, public IPv4, custom metrics, and logs can incur charges. Seven-day log
retention applies to whole groups. Log groups are created by the agent rather than
Terraform resources, so Terraform instance removal does not remove those groups.
Review cleanup separately, including retained logs, before ending the lab. No
destructive command is part of the validation workflow above.
