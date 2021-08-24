locals {
  tfc_workspace_slug_parts                = split("-", var.TFC_WORKSPACE_SLUG)
  env                                     = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  dotnet_core_env                         = local.env == "prod" ? "Production" : local.env == "stage" ? "Staging" : "Dev"
  customers_worker_service_name           = "customers-worker"
  customers_worker_container_name         = "service-customers-worker"
  customers_worker_container_port         = 80
  customers_worker_task_definition_family = "service-customers-worker"
}