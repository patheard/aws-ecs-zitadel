#
# Allows Zitadel to send email using a SES SMTP server
#
resource "aws_ses_domain_identity" "zitadel" {
  domain = aws_route53_zone.zitadel.name
}

resource "aws_route53_record" "zitadel_verification_TXT" {
  zone_id = aws_route53_zone.zitadel.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.zitadel.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.zitadel.verification_token]
}

resource "aws_ses_domain_identity_verification" "ses_verif" {
  domain     = aws_ses_domain_identity.zitadel.id
  depends_on = [aws_route53_record.zitadel_verification_TXT]
}

resource "aws_iam_user" "zitadel_send_email" {
  name = "zitadel_send_email"
}

data "aws_iam_policy_document" "zitadel_send_email" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "zitadel_send_email" {
  name   = "zitadel_send_email"
  policy = data.aws_iam_policy_document.zitadel_send_email.json
}

resource "aws_iam_user_policy_attachment" "zitadel_send_email" {
  user       = aws_iam_user.zitadel_send_email.name
  policy_arn = aws_iam_policy.zitadel_send_email.arn
}

resource "aws_iam_access_key" "zitadel_send_email" {
  user = aws_iam_user.zitadel_send_email.name
}

output "smtp_username" {
  value = aws_iam_access_key.zitadel_send_email.id
}

output "smtp_password" {
  sensitive = true
  value     = aws_iam_access_key.zitadel_send_email.ses_smtp_password_v4
}
