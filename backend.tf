# Setup S3 Backend with DynamoDB state locking
terraform {
  backend "s3" {
    bucket       = "webforx-tf-state-sandbox-us-east-1"
    key          = "platform-engineering/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}