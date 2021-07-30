locals {
  tfc_workspace_slug_parts = split("-", var.TFC_WORKSPACE_SLUG)
  env                      = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  aspnet_core_env          = local.env == "prod" ? "Production" : local.env == "stage" ? "Staging" : "Development"
  service_name             = "bff-api"
  container_name           = "service-bff-api"
  task_definition_family   = "service-bff"
  container_port           = 80
}