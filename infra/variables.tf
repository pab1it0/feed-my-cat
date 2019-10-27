variable "region" {
  type    = "string"
  default = "us-east-1"
}

variable "bucket_prefix" {
  type        = "string"
  default     = "cat-bowl"
  description = "Name of the Bucket to store food images for the office cat."
}

variable "schedule_expression" {
  type        = "string"
  default     = "cron(0/5 * * * ? *)"
  description = "Cron expression for CloudWatch rule."
}

variable "email" {
  type        = "string"
  description = "Email address of the desired alert recipient."
}