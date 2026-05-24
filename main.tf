# ------------------------------
# Terraform configuration
# ------------------------------
terraform {
  required_version = ">=1.15.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.45.0"
    }
  }
}

# ------------------------------
# Provider
# ------------------------------
provider "aws" {
  profile = "terraform"
  region  = "ca-central-1"
}

# ------------------------------
# Variables
# ------------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}