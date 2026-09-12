variable "vpc_id" {
  type        = string
  description = "VPC ID where Lambdas reside"
}

variable "alert_emails" {
  type        = list(string)
  description = "List of email addresses for notifications"
}