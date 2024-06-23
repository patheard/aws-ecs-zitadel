resource "aws_route53_zone" "zitadel" {
  name = var.domain
  tags = local.common_tags
}

resource "aws_route53_record" "zitadel_A" {
  zone_id = aws_route53_zone.zitadel.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.zitadel.dns_name
    zone_id                = aws_lb.zitadel.zone_id
    evaluate_target_health = false
  }
}
