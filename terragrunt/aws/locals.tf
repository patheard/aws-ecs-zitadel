locals {
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
}