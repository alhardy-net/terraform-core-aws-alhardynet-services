locals {
  tfc_workspace_slug_parts           = split("-", var.TFC_WORKSPACE_SLUG)
  env                                = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  service_name = "customers-api"
  container_name = "service-customers-api"
  aws_alb_listener_rule_host_header = env == "prod" ? "${lower(local.service_name)}.alhardy.net" : "${lower(local.service_name)}.${local.env}.alhardy.net"
}