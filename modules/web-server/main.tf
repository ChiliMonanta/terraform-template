variable autoscale_min {}
variable autoscale_max {}
variable autoscale_desired {}
variable ami {}
variable instance_type {}
variable ssh_key_name {}
variable env_name {}

variable availability_zones {
  type = "list"
}

variable bucket_access_logs {}
variable vpc_default_security_group_id {}

variable public_subnets {
  type = "list"
}

variable vpc_id {}
variable app_name {}

resource "aws_security_group" "web" {
  name   = "${var.app_name}-${var.env_name}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.app_name}-${var.env_name}"
  }
}

resource "aws_launch_configuration" "web" {
  name                        = "${var.app_name}-${var.env_name}"
  image_id                    = "${var.ami}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${var.vpc_default_security_group_id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.web.name}"
  key_name                    = "${var.ssh_key_name}"
  associate_public_ip_address = true
  user_data                   = "${data.template_file.user_data.rendered}"

  root_block_device = {
    volume_type           = "standard"
    volume_size           = "100"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/bootstrap/user_data.sh")}"

  vars {
    app_name = "${var.app_name}"
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "${var.app_name}-${var.env_name}"
  min_size             = "${var.autoscale_min}"
  max_size             = "${var.autoscale_max}"
  desired_capacity     = "${var.autoscale_desired}"
  health_check_type    = "EC2"
  launch_configuration = "${aws_launch_configuration.web.name}"
  vpc_zone_identifier  = ["${var.public_subnets}"]
  availability_zones   = "${var.availability_zones}"

  lifecycle {
    create_before_destroy = true
  }

  load_balancers = ["${aws_elb.web.id}"]

  tag {
    key                 = "Name"
    value               = "${var.app_name} - ${var.env_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = "${var.env_name}"
    propagate_at_launch = true
  }
}

resource "aws_elb" "web" {
  name            = "${var.app_name}-${var.env_name}"
  subnets         = ["${var.public_subnets}"]
  security_groups = ["${var.vpc_default_security_group_id}", "${aws_security_group.web.id}"]

  access_logs {
    bucket        = "${var.bucket_access_logs}"
    bucket_prefix = "elb-${var.app_name}-${var.env_name}"
    interval      = 60
    enabled       = true
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name        = "${var.app_name}-${var.env_name}"
    environment = "${var.env_name}"
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.app_name}-ec2_instance_role_${var.env_name}"
  assume_role_policy = "${file("${path.module}/policies/role-trust-policy.json")}"
}

resource "aws_iam_role_policy" "web" {
  name   = "${var.app_name}-ec2_instance_role_policy_${var.env_name}"
  policy = "${file("${path.module}/policies/instance-role-policy.json")}"
  role   = "${aws_iam_role.web.id}"
}

resource "aws_iam_instance_profile" "web" {
  name  = "${var.app_name}-ec2-instance-profile_${var.env_name}"
  path  = "/"
  roles = ["${aws_iam_role.web.name}"]
}

output "public_load_balancer" {
  value = "${aws_elb.web.dns_name}"
}
