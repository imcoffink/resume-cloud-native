variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "account_id" {
  type    = string
  default = "952083499360"
}

variable "github_repo" {
  type    = string
  default = "imcoffink/resume-cloud-native"
}

# GitHub's OIDC "sub" claim includes immutable owner/repo numeric IDs
# (repo:OWNER@ownerId/REPO@repoId:...) rather than the plain slug, so a
# renamed/transferred repo can't reuse another repo's trust. Confirmed via
# CloudTrail from the actual failed AssumeRoleWithWebIdentity calls.
variable "github_actions_subject" {
  type    = string
  default = "repo:imcoffink@49006717/resume-cloud-native@1320436948:ref:refs/heads/main"
}

variable "role_name" {
  type    = string
  default = "resume-cloud-native-github-actions"
}

variable "site_bucket_name" {
  type    = string
  default = "resume-cloud-native-site"
}

variable "cloudfront_distribution_id" {
  type    = string
  default = "E28M0ZORGBDZ7A"
}
