module "zitadel_vpc" {
  source = "github.com/cds-snc/terraform-modules//vpc?ref=v9.5.2"
  name   = "zitadel-${var.env}"

  enable_flow_log                  = true
  availability_zones               = 2
  cidrsubnet_newbits               = 8
  single_nat_gateway               = true
  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_value = var.billing_code
}

resource "aws_network_acl_rule" "http_redirect" {
  network_acl_id = module.zitadel_vpc.main_nacl_id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "smtp_tls_outbound" {
  network_acl_id = module.zitadel_vpc.main_nacl_id
  rule_number    = 105
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 465
  to_port        = 465
}

resource "aws_network_acl_rule" "smtp_tls_inbound" {
  network_acl_id = module.zitadel_vpc.main_nacl_id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 465
  to_port        = 465
}

#
# Security groups
#

# ECS
resource "aws_security_group" "zitadel_ecs" {
  description = "NSG for Zitadel ECS Tasks"
  name        = "zitadel_ecs"
  vpc_id      = module.zitadel_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "zitadel_ecs_egress_internet" {
  description       = "Egress from Zitadel ECS task to internet (HTTPS)"
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.zitadel_ecs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "zitadel_ecs_egress_smtp_tls" {
  description       = "Egress from Zitadel ECS task to SMTP"
  type              = "egress"
  to_port           = 465
  from_port         = 465
  protocol          = "tcp"
  security_group_id = aws_security_group.zitadel_ecs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "zitadel_ecs_ingress_lb" {
  description              = "Ingress from load balancer to Zitadel ECS task"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zitadel_ecs.id
  source_security_group_id = aws_security_group.zitadel_lb.id
}

# Load balancer
resource "aws_security_group" "zitadel_lb" {
  name        = "zitadel_lb"
  description = "NSG for Zitadel load balancer"
  vpc_id      = module.zitadel_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "zitadel_lb_ingress_internet_http" {
  description       = "Ingress from internet to load balancer (HTTP)"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.zitadel_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "zitadel_lb_ingress_internet_https" {
  description       = "Ingress from internet to load balancer (HTTPS)"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.zitadel_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "zitadel_lb_egress_ecs" {
  description              = "Egress from load balancer to Zitadel ECS task"
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zitadel_lb.id
  source_security_group_id = aws_security_group.zitadel_ecs.id
}

# Database
resource "aws_security_group" "zitadel_db" {
  name        = "zitadel_db"
  description = "NSG for Zitadel database"
  vpc_id      = module.zitadel_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "zitadel_db_ingress_ecs" {
  description              = "Ingress to database from Zitadel ECS task"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zitadel_db.id
  source_security_group_id = aws_security_group.zitadel_ecs.id
}

resource "aws_security_group_rule" "keycload_ecs_egress_db" {
  description              = "Egress from Zitadel ECS task to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zitadel_ecs.id
  source_security_group_id = aws_security_group.zitadel_db.id
}