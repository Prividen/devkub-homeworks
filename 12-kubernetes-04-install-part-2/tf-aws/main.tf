terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "centos" {
  most_recent = true
  owners = ["125523088429"]
  filter {
    name   = "name"
    values = ["CentOS Stream 8 x86_64*"]
  }
    filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}


data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_security_group" "ssh_enabled" {
  name = "launch-wizard-1"
}

resource "aws_instance" "kube_control_plane" {
  count = 1
  ami = data.aws_ami.centos.id
  instance_type = "t3.small"
  key_name = "mk-rsa"
  root_block_device {
    volume_size = 50
  }
  vpc_security_group_ids = [
    data.aws_security_group.ssh_enabled.id
  ]
  tags = {
    Name                                            = "kubernetes-mycluster-master${count.index}"
    "kubernetes.io/cluster/mycluster" = "member"
    Role                                            = "master"
  }
}

resource "aws_instance" "kube_node" {
  count = 5
  ami = data.aws_ami.centos.id
  instance_type = "t3.small"
  key_name = "mk-rsa"
  root_block_device {
    volume_size = 100
  }
  vpc_security_group_ids = [
    data.aws_security_group.ssh_enabled.id
  ]
  tags = {
    Name                                            = "kubernetes-mycluster-worker${count.index}"
    "kubernetes.io/cluster/mycluster" = "member"
    Role                                            = "worker"
  }

}


output "Control_nodes" {
  value = {
    for k, v in aws_instance.kube_control_plane :
      "${lookup(v.tags, "Name")}" => "${v.public_ip} / ${v.private_ip}  "
  }
}
output "Worker_nodes" {
  value = {
    for k, v in aws_instance.kube_node :
      "${lookup(v.tags, "Name")}" => "${v.public_ip} / ${v.private_ip}  "
  }
}


output "supplementary_addresses_in_ssl_keys" {
  value = aws_instance.kube_control_plane.*.public_ip
}
