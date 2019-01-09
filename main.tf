## DISCLAIMER: code for demonstration purposes only

variable "region" {
  default = "us-west-2"
}

variable "public_key_contents" {}

provider "aws" {
  region = "${var.region}"
}

output "neptune_cluster_endpoint" {
  value = "${aws_neptune_cluster.demo.endpoint}"
}

output "neptune_cluster_arn" {
  value = "${aws_neptune_cluster.demo.arn}"
}

output "neptune_client_ip" {
  value = "${module.client.public_ip}"
}
