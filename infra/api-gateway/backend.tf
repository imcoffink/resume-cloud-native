terraform {
  backend "s3" {
    bucket       = "resume-cloud-native-tfstate"
    key          = "api-gateway/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
