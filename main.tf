resource "aws_vpc" "this" {
  for_each   = var.spokes
  cidr_block = each.value
  tags       = { Name = "spoke-${each.key}" }
}

locals {
  subnets = {
    "prod_sub"   = { spoke = "prod", az = "eu-north-1a", netnum = 1 }
    "dev_sub"    = { spoke = "dev", az = "eu-north-1a", netnum = 1 }
    "shared_sub" = { spoke = "shared", az = "eu-north-1a", netnum = 1 }
  }
}

resource "aws_subnet" "this" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.this[each.value.spoke].id
  cidr_block        = cidrsubnet(var.spokes[each.value.spoke], 8, each.value.netnum)
  availability_zone = each.value.az
  tags              = { Name = "${each.key}" }
}

resource "aws_ec2_transit_gateway" "this" {
  description                     = "Allow traffic to spokes"
  default_route_table_propagation = "disable"
  default_route_table_association = "disable"
  tags                            = { Name = "{tgw}" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each           = var.spokes
  vpc_id             = aws_vpc.this[each.key].id
  subnet_ids         = [for k, cfg in local.subnets : aws_subnet.this[k].id if cfg.spoke == each.key]
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = { Name = "attach-${each.key}" }
}

locals {
  routetables = {
    spokes = "rtb1"
    shared = "rtb2"
  }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = local.routetables
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = { Name = "${each.key}-rtb" }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = aws_ec2_transit_gateway_vpc_attachment.this
  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.key == "shared" ? "shared" : "spokes"].id
}


resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = aws_ec2_transit_gateway_vpc_attachment.this
  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.key == "shared" ? "spokes" : "shared"].id
}
