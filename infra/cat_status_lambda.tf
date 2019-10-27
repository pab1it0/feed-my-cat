resource "aws_cloudwatch_event_rule" "status-scheduler-event" {
  name                = "status-scheduler-event"
  description         = "status-scheduler-event"
  schedule_expression = "${var.schedule_expression}"
  depends_on          = ["aws_lambda_function.cat-status-lambda"]
}

resource "aws_cloudwatch_event_target" "status-scheduler-event-lambda-target" {
  target_id = "status-scheduler-event-lambda-target"
  rule      = "${aws_cloudwatch_event_rule.status-scheduler-event.name}"
  arn       = "${aws_lambda_function.cat-status-lambda.arn}"
}

resource "aws_iam_role" "cat-status-lambda" {
  name = "cat-status-lambda-role"

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

resource "aws_iam_policy" "scheduler_aws_lambda_basic_execution_role" {
  name        = "scheduler_aws_lambda_basic_execution_role"
  path        = "/"
  description = "AWSLambdaBasicExecutionRole"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:*",
                "ssm:*",
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

resource "aws_iam_role_policy_attachment" "status-basic-exec-role" {
  role       = "${aws_iam_role.cat-status-lambda.name}"
  policy_arn = "${aws_iam_policy.scheduler_aws_lambda_basic_execution_role.arn}"
}

data "archive_file" "status_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/cat-status-lambda"
  output_path = "${path.module}/../build/cat-status-lambda.zip"
}

resource "aws_lambda_function" "cat-status-lambda" {
  filename         = "${path.module}/../build/cat-status-lambda.zip"
  function_name    = "cat-status-lambda"
  role             = "${aws_iam_role.cat-status-lambda.arn}"
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  timeout          = 300
  source_code_hash = "${data.archive_file.status_lambda_zip.output_base64sha256}"

  environment {
    variables = {
      IS_ALERT_EMAIL_SENT_VAR          = "${aws_ssm_parameter.isAlertEmailSent.name}"
      IS_BACK_TO_NORMAL_EMAIL_SENT_VAR = "${aws_ssm_parameter.isBackToNormalEmailSent.name}"
      LAST_FEEDING_TIME_VAR            = "${aws_ssm_parameter.lastFeedingTime.name}"
      TOPIC_ARN                        = "${module.sns_with_email_notification.arn}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.cat-status-lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.status-scheduler-event.arn}"
}

/* 
  Terraform model does't support external confirmation.
  Hence this is an WA which uses CloudFormation to create
  SNS topic and generate subscription along with sending 
  the confirmation email. 
*/
module "sns_with_email_notification" {
  source = "github.com/deanwilson/tf_sns_email"

  display_name  = "Cat feeding alerts"
  email_address = "${var.email}"
  stack_name    = "cat-feeding-alerts"
}
