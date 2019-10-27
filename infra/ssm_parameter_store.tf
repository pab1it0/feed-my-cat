resource "aws_ssm_parameter" "isAlertEmailSent" {
  name  = "/feed_cat/isAlertEmailSent"
  type  = "String"
  value = "0"
}

resource "aws_ssm_parameter" "isBackToNormalEmailSent" {
  name  = "/feed_cat/isBackToNormalEmailSent"
  type  = "String"
  value = "1"
}

resource "aws_ssm_parameter" "lastFeedingTime" {
  name  = "/feed_cat/lastFeedingTime"
  type  = "String"
  value = "0"
}
