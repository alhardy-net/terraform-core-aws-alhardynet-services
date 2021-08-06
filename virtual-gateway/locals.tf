locals {
  virtual_gateway_name     = "${data.terraform_remote_state.ecs.outputs.appmesh_name}-vg"
  service_name             = "virtual-gateway-envoy"
  tfc_workspace_slug_parts = split("-", var.TFC_WORKSPACE_SLUG)
  env                      = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
}