variable env_name {}
variable cidr_block {}

variable availability_zones {
  type = "list"
}

variable public_subnets {
  type = "list"
}

resource "aws_vpc" "public" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = "true"

  tags {
    Name        = "public-${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.public.id}"

  tags {
    Name        = "public-${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_default_route_table" "public" {
  default_route_table_id = "${aws_vpc.public.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }

  tags {
    Name        = "public-${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.public.id}"
  cidr_block              = "${var.public_subnets[count.index]}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  count                   = "${length(var.public_subnets)}"
  map_public_ip_on_launch = "true"

  tags {
    Name        = "${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_default_route_table.public.id}"
  count          = "${length(var.public_subnets)}"
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.public.default_network_acl_id}"

  # no rules defined, deny all traffic in this ACL
  tags {
    Name        = "default-${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_network_acl" "all" {
  vpc_id     = "${aws_vpc.public.id}"
  subnet_ids = ["${aws_subnet.public.*.id}"]

  egress {
    protocol   = "-1"
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name        = "public-${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_default_security_group" "vpc-default" {
  vpc_id = "${aws_vpc.public.id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "default-${var.env_name}"
    environment = "${var.env_name}"
  }
}

output "default_security_group_id" {
  value = "${aws_default_security_group.vpc-default.id}"
}

output "vpc_id" {
  value = "${aws_vpc.public.id}"
}

# Workaround! Waiting for depend_on between modules
output "subnets_id" {
  value = ["${aws_subnet.public.*.id}"]
}
