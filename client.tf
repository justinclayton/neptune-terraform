## DISCLAIMER: code for demonstration purposes only

resource "aws_key_pair" "neptune_client" {
  key_name   = "neptune-client"
  public_key = "${var.public_key_contents}"
}

module "client" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "1.12.0"

  name           = "neptune-client"
  instance_count = 1

  ami                         = "ami-e251209a"
  instance_type               = "r4.2xlarge"
  key_name                    = "${aws_key_pair.neptune_client.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.neptune_client.id}"]
  subnet_id                   = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.profile.name}"

  user_data = <<EOF1
#!/bin/bash -xe
yum update -y 
yum -y install java-1.8.0-devel
yum -y remove java-1.7.0-openjdk
cur_dir=$PWD
cd /home/ec2-user/
pip install --upgrade awscli

cat <<-"EOF2" >> README.md
  ## Connecting To Neptune
  See https://docs.aws.amazon.com/neptune/latest/userguide/quickstart.html#quickstart-graph-gremlin to learn more about using Gremlin with Neptune.
  ```
  $ cd apache-tinkerpop-gremlin-console-3.3.2
  $ ./bin/gremlin.sh
  gremlin> :remote connect tinkerpop.server conf/neptune-remote.yaml
  gremlin> :remote console
  g.addV('person').property(id, '1').property('name', 'martin')
  g.V('1').property(single, 'name', 'marko')
  g.V('1').property('age', 29)
  g.addV('person').property(id, '2').property('name', 'vadas').property('age', 27).next()
  g.addV('software').property(id, '3').property('name', 'lop').property('lang', 'java').next()
  g.addV('person').property(id, '4').property('name', 'josh').property('age', 32).next()
  g.addV('software').property(id, '5').property('name', 'ripple').property('ripple', 'java').next()
  g.addV('person').property(id, '6').property('name', 'peter').property('age', 35)
  g.V('1').addE('knows').to(g.V('2')).property('weight', 0.5).next()
  g.addE('knows').from(g.V('1')).to(g.V('4')).property('weight', 1.0)
  g.V('1').addE('created').to(g.V('3')).property('weight', 0.4).next()
  g.V('4').addE('created').to(g.V('5')).property('weight', 1.0).next()
  g.V('4').addE('knows').to(g.V('3')).property('weight', 0.4).next()
  g.V('6').addE('created').to(g.V('3')).property('weight', 0.2)
  g.V().hasLabel('person')
  g.V().has('name', 'marko').out('knows').valueMap()
  gremlin> :exit
  ```
EOF2

wget https://archive.apache.org/dist/tinkerpop/3.3.2/apache-tinkerpop-gremlin-console-3.3.2-bin.zip
unzip apache-tinkerpop-gremlin-console-3.3.2-bin.zip
rm apache-tinkerpop-gremlin-console-3.3.2-bin.zip
cd apache-tinkerpop-gremlin-console-3.3.2/conf

cat <<-"EOF3" >> neptune-remote.yaml
hosts: [${aws_neptune_cluster.demo.endpoint}]
port: 8182
serializer: { className: org.apache.tinkerpop.gremlin.driver.ser.GryoMessageSerializerV3d0, config: { serializeResultToString: true }}
EOF3

EOF1
}

resource "aws_security_group" "neptune_client" {
  name        = "neptune-client"
  description = "Security group for Neptune client"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8182
    to_port     = 8182
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "profile" {
  name = "profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "neptune_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": ["ec2.amazonaws.com", "rds.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "neptune" {
  policy_arn = "arn:aws:iam::aws:policy/NeptuneFullAccess"
  role       = "${aws_iam_role.role.name}"
}
