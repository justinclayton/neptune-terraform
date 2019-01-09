## DISCLAIMER: code for demonstration purposes only
resource "aws_neptune_cluster" "demo" {
  cluster_identifier                  = "demo"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false
  apply_immediately                   = true
  neptune_subnet_group_name           = "${aws_neptune_subnet_group.demo.name}"
  vpc_security_group_ids              = ["${aws_security_group.neptune_client.id}"]
  iam_roles                           = ["${aws_iam_role.role.arn}"]
}

resource "aws_neptune_cluster_instance" "demo" {
  count              = 2
  cluster_identifier = "${aws_neptune_cluster.demo.id}"
  engine             = "neptune"
  instance_class     = "db.r4.large"
  apply_immediately  = true

  # publicly_accessible = true
}

resource "aws_neptune_subnet_group" "demo" {
  name       = "demo"
  subnet_ids = ["${module.vpc.public_subnets}"]
}
