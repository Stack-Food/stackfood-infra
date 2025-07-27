terraform {
  backend "s3" {
    bucket = "leo-teste-terraform"
    key    = "leo-teste-terraform.tfstate"
    region = "us-east-1"
  }
}

