terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ACM certificates used by CloudFront must live in us-east-1, regardless
# of where the rest of the stack runs.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# The site bucket (infra/site) lives in eu-central-1; its bucket policy
# has to be applied through a provider configured for that region.
provider "aws" {
  alias  = "site_region"
  region = var.site_region
}
