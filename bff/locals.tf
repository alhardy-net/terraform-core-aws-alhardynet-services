locals {
  tfc_workspace_slug_parts          = split("-", var.TFC_WORKSPACE_SLUG)
  env                               = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  service_name                      = "bff-api"
  container_name                    = "service-bff-api"
  task_definition_family             = "service-bff"
  aws_alb_listener_rule_host_header = local.env == "prod" ? "${lower(local.service_name)}.alhardy.net" : local.env == "local" ? "${lower(local.service_name)}.dev.alhardy.net" : "${lower(local.service_name)}.${local.env}.alhardy.net"
}