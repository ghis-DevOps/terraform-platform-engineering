variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EFS mount targets"
}