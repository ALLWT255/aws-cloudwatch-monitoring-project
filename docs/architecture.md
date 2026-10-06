# Architecture

The top-level Terraform configuration provisions one VPC, a public subnet in
`us-east-1a`, an internet gateway, a public default route and subnet association,
a security group, and an Amazon Linux 2023 EC2 instance running NGINX.
An IAM role, `CloudWatchAgentServerPolicy` attachment, and instance profile let
the agent publish telemetry without static credentials on the instance.

```text
HTTP client -> Internet gateway / public subnet -> Security group -> NGINX :80
                                                                    |
EC2 instance role -> CloudWatch agent (cwagent) -> CloudWatch metrics and logs
```

User data installs NGINX and the agent, writes the adjacent
[`cloudwatch-agent.json`](../cloudwatch-agent.json), fetches that configuration,
starts the agent, and enables both services at boot. Group permissions and
logrotate configuration preserve `cwagent` read access to NGINX logs. Terraform
waits for the public route association and IAM policy attachment before launch.
The instance uses its public subnet for package downloads and AWS API access.

The configuration collects `mem_used_percent` and `disk_used_percent` every
60 seconds in `CWAgent`. EC2 dimensions include ImageId, InstanceId, InstanceType,
and AutoScalingGroupName where applicable; this standalone server has no ASG.
Access and error files flow to `access.log` and `error.log`, respectively, with
instance-ID streams, STANDARD class, and seven-day group retention.

The original server's memory graph was manually verified. A subsequent EC2-only
replacement verified automated startup, HTTP service, and both log streams.
New-server memory metrics and disk metrics are not proven by the screenshots.
See the [README evidence](../README.md#automated-configuration-and-fresh-server-verification).

This is a single-instance HTTP lab, not a highly available production service.
SSH and HTTP ingress are currently public; restrict SSH for real deployments.
There is no load balancer, TLS, CloudWatch dashboard, or alarm in this configuration.
The security group and IAM resources survive the documented EC2-only replacement.
