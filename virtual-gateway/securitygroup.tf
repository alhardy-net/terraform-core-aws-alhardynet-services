resource "aws_security_group" "virtual_gateway" {
  name        = "${local.service_name}-SG"
  description = "Security group for service to communicate in and out of the virtual gateway"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "${local.service_name}-SG"
  }
}

resource "aws_security_group_rule" "ephemeral_ports_ingress" {
  type              = "ingress"
  from_port         = 32768
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.virtual_gateway.id
}

resource "aws_security_group_rule" "virtual_gateway_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.virtual_gateway.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.virtual_gateway.id
}