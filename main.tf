# GitHub Actions test 4
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
  backend "s3" {
    bucket = "tabi-note-tfstate"
    key    = "tabi-note/terraform.tfstate"
    region = "ca-central-1"
  }
}

# ------------------------------
# Provider
# ------------------------------
provider "aws" {
  region = "ca-central-1"
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

