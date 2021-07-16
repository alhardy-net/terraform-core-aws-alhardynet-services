locals {
  tfc_workspace_slug_parts          = split("-", var.TFC_WORKSPACE_SLUG)
  env                               = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  service_name                      = "customers-api"
  container_name                    = "service-customers-api"
  container_port                    = 80
}