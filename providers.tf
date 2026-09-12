terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Task 4: Default provider enforcement strictly configured for us-east-1
provider "aws" {
  region = var.aws_region

  # Task 2: Default mandatory tags across all provisioned resources
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Project     = var.project
      CostCenter  = var.cost_center
    }
  }
}