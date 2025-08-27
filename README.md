
# Terraform AWS Blue-Green Deployment Demo

A Terraform project demonstrating a zero-downtime blue-green deployment strategy on AWS using Auto Scaling Groups, an Application Load Balancer, and weighted Route53 records.
This kind of deployment enables one control versions of an application with minimum downtime. An engineer can also implement a Canary test using this architecture style, by toggling 
the weight on the blue or green environments, through DNS records from traffic distribution. 

## Architecture

<img width="460" height="408" alt="blue-green-archi" src="https://github.com/user-attachments/assets/fe22f46d-ea02-43a2-bbda-a945f77586bb" />

- **Blue Environment**: Serves live traffic (weight=100).
- **Green Environment**: Staging environment for new versions (weight=0).
- **Route53**: Weighted DNS records control traffic distribution.
- **ALB**: Routes traffic to the correct Target Group.
- **ASG**: Manages EC2 instances for each environment.

## Prerequisites

1.  **AWS Account:** With credentials configured for Terraform (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`).
2.  **Terraform:** v1.0 or newer installed.
3.  **AWS CLI:** Installed (used by the user-data script on instances to query tags).
4.  **EC2 Key Pair:** Create a Key Pair in your AWS console (us-east-1) and set its name in `compute.tf` (`key_name` in the launch template).
5.  **(Optional) Domain:** A domain managed by Route53 for the full weighted routing demo.

## Usage

This project uses Terraform workspaces to manage the separate blue and green environments.

### 1. Initialize Terraform

```bash
terraform init
```
