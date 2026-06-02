# AWS CloudWatch Monitoring Project

## Project Overview

This project demonstrates how to deploy AWS infrastructure using Terraform and prepare an EC2 instance for monitoring with Amazon CloudWatch.

The goal of the project was to gain hands-on experience with Infrastructure as Code (IaC), IAM roles, EC2 provisioning, networking, and CloudWatch monitoring concepts used by Cloud Engineers, DevOps Engineers, and Site Reliability Engineers (SREs).

---

## Technologies Used

* AWS VPC
* AWS EC2
* AWS IAM
* AWS CloudWatch
* Terraform
* Amazon Linux 2023

---

## Architecture

The infrastructure consists of:

* Custom VPC
* Public Subnet
* Internet Gateway
* Route Table
* Security Group
* EC2 Instance
* IAM Role
* CloudWatch Agent Permissions

Traffic flows from the Internet through the VPC networking components to the EC2 web server. CloudWatch is used to collect monitoring data from the instance.

---

## Terraform Resources

### Networking

* VPC
* Public Subnet
* Internet Gateway
* Route Table
* Route Table Association

### Security

* Security Group allowing:

  * HTTP (Port 80)
  * SSH (Port 22)

### IAM

* IAM Role for EC2
* CloudWatchAgentServerPolicy
* Instance Profile

### Compute

* Amazon Linux 2023 EC2 Instance
* Dynamic AMI lookup using Terraform Data Sources

---

## Monitoring Objectives

The project was designed to monitor:

* CPU Utilization
* Memory Usage
* Disk Utilization
* Application Logs
* System Health Metrics

These metrics help engineers identify performance issues and troubleshoot production workloads.

---

## Key Terraform Concepts Demonstrated

* Resource Creation
* Variables
* Outputs
* IAM Role Attachments
* Data Sources
* Dynamic AMI Selection
* Infrastructure as Code Best Practices

---

## Security Considerations

For lab purposes, SSH access was configured using 0.0.0.0/0.

In a production environment, SSH access should be restricted to trusted IP addresses and administrative networks.

---

## Future Improvements

* Automate NGINX installation using user_data
* Automate CloudWatch Agent installation
* Create CloudWatch Dashboards with Terraform
* Create CloudWatch Alarms with Terraform
* Implement GitHub Actions validation pipeline
* Add remote Terraform state management

---

## Lessons Learned

This project reinforced the importance of:

* Infrastructure automation
* IAM role management
* AWS networking fundamentals
* Monitoring and observability
* Terraform resource dependencies
* Cloud operational best practices
