data "terraform_remote_state" "cdn" {
  backend = "s3"

  config = {
    bucket = "resume-cloud-native-tfstate"
    key    = "cdn/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "HostedZone created by Route53 Registrar"
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.cdn.outputs.distribution_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.cdn.outputs.distribution_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# Pre-existing ACM DNS validation record for the imported certificate
# (infra/cdn). The certificate is already ISSUED; this record is imported
# for completeness rather than to trigger (re)validation.
resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "_59c2955ccfb133673f83194559657ee8.iagomisko.com"
  type    = "CNAME"
  ttl     = 300
  records = ["_d2f7e3af7f16c400cf0eca7a94ec1f7c.mhbtsbpdnt.acm-validations.aws."]
}
