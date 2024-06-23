#
# Root Terragrunt config inherited by all modules
# Sets up remote state and common variables and expects env_vars.hcl to be present
# to set an environment's global varialbes.
#
locals {
  billing_code = "${local.env_vars.inputs.product_name}-${local.env_vars.inputs.env}"
  env_vars     = read_terragrunt_config("./env_vars.hcl")
}

inputs = {
  account_id   = local.env_vars.inputs.account_id
  billing_code = local.billing_code
  domain       = local.env_vars.inputs.domain
  env          = local.env_vars.inputs.env
  product_name = local.env_vars.inputs.product_name
  region       = local.env_vars.inputs.region
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("./common/provider.tf")
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("./common/common_variables.tf")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt             = true
    bucket              = "${local.billing_code}-tf"
    dynamodb_table      = "terraform-state-lock-dynamo"
    region              = "ca-central-1"
    key                 = "${path_relative_to_include()}/terraform.tfstate"
    s3_bucket_tags      = { CostCenter : local.billing_code }
    dynamodb_table_tags = { CostCenter : local.billing_code }
  }
}