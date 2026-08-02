terraform {
  backend "s3" {
    bucket       = "resume-cloud-native-tfstate"
    key          = "lambda/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
