variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "sandbox"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "project" {
  type    = string
  default = "webforx"
}

variable "cost_center" {
  type    = string
  default = "cc-101"
}

variable "alert_emails" {
  type    = list(string)
  default = ["ops@webforx.com"]
}