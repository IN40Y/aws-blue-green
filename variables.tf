variable "environment" {
  description = "The deployment environment (blue, green)"
  type        = string
  validation {
    condition     = contains(["blue", "green"], var.environment)
    error_message = "Environment must be 'blue' or 'green'."
  }
}

variable "app_version" {
  description = "The version of the application to deploy (e.g., v1, v2)"
  type        = string
  default     = "v1"
}

variable "domain_name" {
  description = "The base domain name for the Route53 record (e.g., mydomain.com). Leave empty if you don't have a domain."
  type        = string
  default     = ""
}

variable "weight" {
  description = "The weight for the Route53 weighted record (0 or 100)"
  type        = number
  default     = 100
  validation {
    condition     = var.weight == 0 || var.weight == 100
    error_message = "Weight must be either 0 or 100 for this demo."
  }
}

# You can set this in a terraform.tfvars file or via the command line
variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}
