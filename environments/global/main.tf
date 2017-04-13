variable region {}
variable aws_profile {}

variable buckets_names {
  type = "list"
}

variable bucket_tag_names {
  type = "list"
}

variable bucket_tag_environments {
  type = "list"
}

# http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
variable region_elb_account_id {}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile}"
}

resource "aws_s3_bucket" "global" {
  bucket = "${element(var.buckets_names, count.index)}"
  acl    = "private"
  region = "${var.region}"
  count  = "${length(var.buckets_names)}"
  policy = "${element(data.template_file.policy.*.rendered, count.index)}"

  tags {
    Name        = "${element(var.bucket_tag_names, count.index)}"
    Environment = "${element(var.bucket_tag_environments, count.index)}"
  }
}

data "template_file" "policy" {
  template = "${file("${path.module}/policies/bucket-policy.json")}"
  count    = "${length(var.buckets_names)}"

  vars {
    region_elb_account_id = "${var.region_elb_account_id}"
    bucket                = "${element(var.buckets_names, count.index)}"
  }
}
