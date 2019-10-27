resource "aws_iam_role" "cat-feeder-lambda" {
  name = "cat-feeder-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "feeder_aws_lambda_basic_execution_role" {
  name        = "feeder_aws_lambda_basic_execution_role"
  path        = "/"
  description = "AWSLambdaBasicExecutionRole"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:*",
                "s3:*",
                "rekognition:*",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "feeder-basic-exec-role" {
  role       = "${aws_iam_role.cat-feeder-lambda.name}"
  policy_arn = "${aws_iam_policy.feeder_aws_lambda_basic_execution_role.arn}"
}

data "archive_file" "feeder-lambda-zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/cat-feeder-lambda"
  output_path = "${path.module}/../build/cat-feeder-lambda.zip"
}

resource "aws_lambda_function" "cat-feeder-lambda" {
  filename         = "${path.module}/../build/cat-feeder-lambda.zip"
  function_name    = "cat-feeder-lambda"
  role             = "${aws_iam_role.cat-feeder-lambda.arn}"
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  timeout          = 300
  source_code_hash = "${data.archive_file.feeder-lambda-zip.output_base64sha256}"

  environment {
    variables = {
      LAST_FEEDING_TIME_VAR = "${aws_ssm_parameter.lastFeedingTime.name}"
    }
  }
}

resource "aws_s3_bucket_notification" "my-trigger" {
  bucket = "${aws_s3_bucket.bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.cat-feeder-lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "feeder-lambda-permissions" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.cat-feeder-lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.bucket.arn}"
}