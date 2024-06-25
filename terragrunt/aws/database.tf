#
# RDS Postgress cluster
#
module "zitadel_database" {
  source = "github.com/cds-snc/terraform-modules//rds?ref=v9.5.2"
  name   = "zitadel-${var.env}"

  database_name           = var.zitadel_database
  engine                  = "aurora-postgresql"
  engine_version          = "16.2"
  instances               = 2
  instance_class          = "db.serverless"
  serverless_min_capacity = var.zitadel_database_min_acu
  serverless_max_capacity = var.zitadel_database_max_acu

  username               = var.zitadel_database_admin_username
  password               = var.zitadel_database_admin_password
  proxy_secret_auth_arns = [aws_secretsmanager_secret.zidatel_database_proxy_auth.arn]

  backup_retention_period      = 7
  preferred_backup_window      = "02:00-04:00"
  performance_insights_enabled = false

  vpc_id             = module.zitadel_vpc.vpc_id
  subnet_ids         = module.zitadel_vpc.private_subnet_ids
  security_group_ids = [aws_security_group.zitadel_db.id]

  billing_tag_value = var.billing_code
}

resource "aws_ssm_parameter" "zitadel_database" {
  name  = "zitadel_database"
  type  = "SecureString"
  value = var.zitadel_database
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_host" {
  name  = "zitadel_database_host"
  type  = "SecureString"
  value = module.zitadel_database.proxy_endpoint
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_username" {
  name  = "zitadel_database_username"
  type  = "SecureString"
  value = var.zitadel_database_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_password" {
  name  = "zitadel_database_password"
  type  = "SecureString"
  value = var.zitadel_database_password
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_admin_username" {
  name  = "zitadel_database_admin_username"
  type  = "SecureString"
  value = var.zitadel_database_admin_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_admin_password" {
  name  = "zitadel_database_admin_password"
  type  = "SecureString"
  value = var.zitadel_database_admin_password
  tags  = local.common_tags
}

resource "aws_secretsmanager_secret" "zidatel_database_proxy_auth" {
  name = "zidatel_database_proxy_auth"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "zidatel_database_proxy_auth" {
  secret_id = aws_secretsmanager_secret.zidatel_database_proxy_auth.id
  secret_string = jsonencode({
    username = var.zitadel_database_username,
    password = var.zitadel_database_password
  })
}
