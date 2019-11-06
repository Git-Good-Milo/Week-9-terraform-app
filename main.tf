provider "aws" {
region = "eu-west-1"
}

# Launch first ec2 instance

resource "aws_instance" "app_instance"{
  ami = "${var.app_ami_id}"
  instance_type = "${var.instance_type_default}"
  key_name = "${aws_key_pair.deployer.key_name}"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.my_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_tls_milo.id}"]
  user_data = "${data.template_file.app_instance.rendered}"
  tags = {
    Name = "${var.Name_default}"
    }

  }

resource "aws_subnet" "my_subnet" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "10.10.20.0/24"
  tags = {
    Name = "${var.Name_default}"
  }
}

resource "aws_security_group" "allow_tls_milo" {
  name        = "allow_tls_milo"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # cidr_blocks = # add a CIDR block here
  }
  ingress {
    # TLS (change to whatever ports you need)
    description = "Use port 22 to ssh into instance only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["212.161.55.68/32"]
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # cidr_blocks = # add a CIDR block here
  }
  ingress {
    # TLS (change to whatever ports you need)
    description = "Use port 3000 to allow access to app"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_route_table" "r_miles" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "212.161.55.68/32"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }
  tags = {
    Name = "main"
  }
}
# Grab a reference to the internet gateway for our vpc
data "aws_internet_gateway" "default" {
  filter {
  name = "attachment.vpc-id"
  values = ["${var.vpc_id}"]
  }
}

resource "aws_route_table_association" "assoc" {
  subnet_id = "${aws_subnet.my_subnet.id}"
  route_table_id = "${aws_route_table.r_miles.id}"
}

# sending scripts to instance
data "template_file" "app_instance"{
  template = "${file("./scripts/app/init.sh.tpl")}"
}

resource "aws_key_pair" "deployer" {
  key_name   = "mile-terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDRUUjRHvn8tH9gtwTnel5WsdbxJOpj+f3LH58GeJA6XDWeskKXQWKQYdf/YPxET1UmBGoTzElIlJe7n13tRNlqlJ6K5eGE3M7TBw0KpYTUiGqGBgYfZbw9Dl+4ucjl+5O5X/CxTUPI67zR4VyNo3pxsGE+u/MLHkHAqOpoKuECVVoIAPh8Npxii/pr5/zuJXSwEMeHNUvS9s8T3Bd/ghD9aEX8HaNkkZleh2BlYvRa0UJ8GV1BkJve1x3Z5mdpk7kjdv9BaI1wJBGtg1YS+MA5LfZXev872TWxG0uYfg0iqpiJTvksm4oYUEXEJMq2l1K+Xbh4OOL8WhtB04X67mtSgvRxfvMmEoBcBqCc2XqhsD9fSA7NbCrYJFqNR5OCZzLWao1LjSZXrEZHnmh4b8rY1fneU32033K3H1MTFBRv9ig9ryUjmrC/qpuuC7urN4MGMXZ07+20TOSXNT4DIvFnA7CHMtI119BM/B3SKu4QVRzUFvHOc8WHvj3eJ3p1Mm8= Miles Eastwood@lt-rich-w74"
}
