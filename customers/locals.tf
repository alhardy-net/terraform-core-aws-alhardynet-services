locals {
  tfc_workspace_slug_parts = split("-", var.TFC_WORKSPACE_SLUG)
  env                      = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
  service_name             = "customers-api"
  container_name           = "service-customers-api"
  container_port           = 80
  task_definition_family   = "service-customers"
  envoy_image              = "840364872350.dkr.ecr.ap-southeast-2.amazonaws.com/aws-appmesh-envoy:v1.18.3.0-prod"
  xray_image               = "amazon/aws-xray-daemon:1"
}