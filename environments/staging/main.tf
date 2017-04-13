variable region {}
variable aws_profile {}
variable autoscale_min {}
variable autoscale_max {}
variable autoscale_desired {}
variable ami {}
variable instance_type {}
variable ssh_key_name {}
variable env_name {}
variable cidr_block {}

variable availability_zones {
  type = "list"
}

variable public_subnets {
  type = "list"
}

variable bucket_access_logs {}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile}"
}

module "public_network" {
  source             = "../../modules/public_network"
  env_name           = "${var.env_name}"
  cidr_block         = "${var.cidr_block}"
  availability_zones = "${var.availability_zones}"
  public_subnets     = "${var.public_subnets}"
}

module "app1" {
  source                        = "../../modules/web-server"
  app_name                      = "app1"
  env_name                      = "${var.env_name}"
  availability_zones            = "${var.availability_zones}"
  autoscale_min                 = "${var.autoscale_min}"
  autoscale_max                 = "${var.autoscale_max}"
  autoscale_desired             = "${var.autoscale_desired}"
  ami                           = "${var.ami}"
  instance_type                 = "${var.instance_type}"
  ssh_key_name                  = "${var.ssh_key_name}"
  bucket_access_logs            = "${var.bucket_access_logs}"
  public_subnets                = ["${module.public_network.subnets_id}"]
  vpc_id                        = "${module.public_network.vpc_id}"
  vpc_default_security_group_id = "${module.public_network.default_security_group_id}"
}

output "app1" {
  value = "${module.app1.public_load_balancer}"
}
