resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${var.bucket_prefix}-"
  acl           = "private"
}
