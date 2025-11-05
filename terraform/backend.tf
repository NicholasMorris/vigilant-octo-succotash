terraform {
  backend "s3" {
    bucket = "ila43kmsba12"
    key    = "social-battery/terraform.tfstate"
    region = "ap-southeast-2"
  }
}
