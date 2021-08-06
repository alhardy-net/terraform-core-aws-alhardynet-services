output "appmesh_virtual_gateway_name" {
  value       = aws_appmesh_virtual_gateway.this.name
  description = "The name of the App Mesh Virtual Gateway"
}