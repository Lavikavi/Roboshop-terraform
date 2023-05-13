terraform {
  backend "s3" {
    bucket = "terraform-a62"
    key    = "roboshop/dev/terraform.tfstate"
    region = "us-east-1"
  }
}