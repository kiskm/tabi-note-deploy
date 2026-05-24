# GitHub Actions test 2
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

# ------------------------------
# S3 Remote State
# ------------------------------
# terraform {
#   backend "s3" {
#     bucket = "your-tfstate-bucket"
#     key    = "tabi-note/terraform.tfstate"
#     region = "ca-central-1"
#   }
# }