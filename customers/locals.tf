locals {
  tfc_workspace_slug_parts             = split("-", var.TFC_WORKSPACE_SLUG)
  env                                  = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  aspnet_core_env                      = local.env == "prod" ? "Production" : local.env == "stage" ? "Staging" : "Dev"
  customers_api_service_name           = "customers-api"
  customers_api_container_name         = "service-customers-api"
  customers_api_container_port         = 80
  customers_api_task_definition_family = "service-customers"
}