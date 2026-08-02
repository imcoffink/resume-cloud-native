terraform {
  backend "s3" {
    bucket       = "resume-cloud-native-tfstate"
    key          = "dns/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
