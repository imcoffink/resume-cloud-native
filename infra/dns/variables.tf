variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "domain_name" {
  type    = string
  default = "iagomisko.com"
}

# Fixed AWS-owned hosted zone ID for any CloudFront distribution alias target.
# Same value for every account/distribution, not specific to this project.
variable "cloudfront_hosted_zone_id" {
  type    = string
  default = "Z2FDTNDATAQYW2"
}
