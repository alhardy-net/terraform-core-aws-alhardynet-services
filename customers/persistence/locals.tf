locals {
  tfc_workspace_slug_parts             = split("-", var.TFC_WORKSPACE_SLUG)
  env                                  = element(local.tfc_workspace_slug_parts, length(local.tfc_workspace_slug_parts) - 1)
}