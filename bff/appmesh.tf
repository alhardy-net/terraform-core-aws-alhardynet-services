resource "aws_appmesh_virtual_node" "this" {
  name      = "${local.service_name}-node"
  mesh_name = data.terraform_remote_state.ecs.outputs.appmesh_name
  
  spec {
    listener {
      port_mapping {
        port     = "80"
        protocol = "http"
      }
      health_check {
        protocol            = "http"
        path                = "/"
        port                = 80
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }
    
    service_discovery {
      aws_cloud_map {
        service_name   = aws_service_discovery_service.this.name
        namespace_name = data.terraform_remote_state.ecs.outputs.service_discovery_private_dns_namespace_name
      }
    }
  }
}

resource "aws_appmesh_virtual_service" "this" {
  name      = "${local.service_name}.${data.terraform_remote_state.ecs.outputs.service_discovery_private_dns_namespace_name}"
  mesh_name = data.terraform_remote_state.ecs.outputs.appmesh_name
  
  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.this.name
      }
    }
  }
}

resource "aws_appmesh_gateway_route" "route" {
  name                 = "${local.service_name}-route"
  virtual_gateway_name = data.terraform_remote_state.ecs.outputs.appmesh_virtual_gateway_name
  mesh_name            = data.terraform_remote_state.ecs.outputs.appmesh_name
  
  spec {
    backend {
      virtual_service {
        virtual_service_name = data.terraform_remote_state.customers-service.virtual_service_name
      }
    }
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.this.name
          }
        }
      }

      match {
        prefix = "/"
      }
    }
  }
}