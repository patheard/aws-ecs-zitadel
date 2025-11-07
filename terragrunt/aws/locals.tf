locals {
  protocol_versions = toset(["HTTP1", "HTTP2"])
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
}