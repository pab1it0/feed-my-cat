output "s3_url" {
  value       = "s3://${aws_s3_bucket.bucket.id}"
  description = "Bucket id."
}

