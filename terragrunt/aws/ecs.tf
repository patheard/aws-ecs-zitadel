locals {
  container_env = [
    {
      "name"  = "ZITADEL_EXTERNALDOMAIN",
      "value" = var.domain
    },
  ]
  container_secrets = [
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_DATABASE"
      "valueFrom" = aws_ssm_parameter.zitadel_database.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_HOST"
      "valueFrom" = aws_ssm_parameter.zitadel_database_host.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_USER_USERNAME"
      "valueFrom" = aws_ssm_parameter.zitadel_database_username.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_USER_PASSWORD"
      "valueFrom" = aws_ssm_parameter.zitadel_database_password.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME"
      "valueFrom" = aws_ssm_parameter.zitadel_database_admin_username.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD"
      "valueFrom" = aws_ssm_parameter.zitadel_database_admin_password.arn
    },
    {
      "name"      = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME"
      "valueFrom" = aws_ssm_parameter.zitadel_admin_username.arn
    },
    {
      "name"      = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD"
      "valueFrom" = aws_ssm_parameter.zitadel_admin_password.arn
    },
    {
      "name"      = "ZITADEL_MASTERKEY"
      "valueFrom" = aws_ssm_parameter.zitadel_secret_key.arn
    },
  ]
}

module "zitadel_ecs" {
  source = "github.com/cds-snc/terraform-modules//ecs?ref=v9.5.2"

  cluster_name = "zitadel"
  service_name = "zitadel"
  task_cpu     = 4096
  task_memory  = 8192

  enable_execute_command = true

  # Scaling
  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 2

  # Task definition
  container_image                     = "${aws_ecr_repository.zitadel.repository_url}:latest"
  container_command                   = ["start-from-init", "--masterkeyFromEnv", "--tlsMode", "enabled", "--config", "/app/config.yaml", "--steps", "/app/steps.yaml"]
  container_host_port                 = 8080
  container_port                      = 8080
  container_environment               = local.container_env
  container_secrets                   = local.container_secrets
  container_read_only_root_filesystem = false
  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_ssm_parameters.json
  ]
  task_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_create_tunnel.json
  ]

  # Networking
  lb_target_group_arn = aws_lb_target_group.zitadel.arn
  subnet_ids          = module.zitadel_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.zitadel_ecs.id]

  billing_tag_value = var.billing_code
}

#
# IAM policies
#
data "aws_iam_policy_document" "ecs_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.zitadel_admin_username.arn,
      aws_ssm_parameter.zitadel_admin_password.arn,
      aws_ssm_parameter.zitadel_database.arn,
      aws_ssm_parameter.zitadel_database_host.arn,
      aws_ssm_parameter.zitadel_database_username.arn,
      aws_ssm_parameter.zitadel_database_password.arn,
      aws_ssm_parameter.zitadel_database_admin_username.arn,
      aws_ssm_parameter.zitadel_database_admin_password.arn,
      aws_ssm_parameter.zitadel_secret_key.arn
    ]
  }
}

data "aws_iam_policy_document" "ecs_task_create_tunnel" {
  statement {
    sid    = "CreateSSMTunnel"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

#
# SSM Parameters
#
resource "aws_ssm_parameter" "zitadel_secret_key" {
  name  = "zitadel_secret_key"
  type  = "SecureString"
  value = var.zitadel_secret_key
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_admin_username" {
  name  = "zitadel_admin_username"
  type  = "SecureString"
  value = var.zitadel_admin_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_admin_password" {
  name  = "zitadel_admin_password"
  type  = "SecureString"
  value = var.zitadel_admin_password
  tags  = local.common_tags
}
