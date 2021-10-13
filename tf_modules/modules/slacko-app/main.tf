
data "aws_ami" "slacko-app"{
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["Amazon*"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}


data "aws_subnet" "subnet_public" {
    cidr_block = var.subnet_cidr
}

# SSH Keygen
resource "aws_key_pair" "slacko-sshkey" {
    key_name = "slacko-app-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIhZsGVHYSyYtgo/UjF7KFBnA+NjkuCn8TvpSzygvmnpqjJXEv1HBfe5jN/rhbvvK/N2Suzb1HtpEVzXQnhf1zlW7fGNAhhIo7WYAhmFViqzseVDJv09U+GZjRKsUvLXccDzYQsFVi+YQ6eS0i52vR5yeOG8KkgISUctp0NdyhNNObL7Dxu/zSUFtVjvOrora+i2PdcG3w8rwF/5mqqoocdGiqRw1gvt1Lz57Df7XRe9h+rTdaj5/Tyh/b0GCCEZqAGFJ84hYwdwXqp4VkbU/MF5l3Obk+GBV9fUbVQWgVSj7i+IoHWt3hlBXKV/uUgkVPTW4s8zjW4ekuZGDJXFjn+wqOfblwBDudsPVAqebW6KsK+/yd+fJD5OYNYhCbi9+9mPG6zbo7Cvoj+N5hmr4UNQqUrcY5nJik1oDjJPYXu3NgsK7NV7z2RdBKuyik32stKHqxXHgBJoVqixiRHnMK8AWfBv8ITvuHbSqLMhlKn/Wn85avt2yTzG/Hy9EPIw0= slacko-app"
  
}


resource "aws_instance" "slacko-app" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id
    associate_public_ip_address = true
    tags = {
      Name = "slacko-app-Andre"
    }
    key_name = aws_key_pair.slacko-sshkey.id
    user_data = file("${path.module}/files/ec2.sh")

}

resource "aws_instance" "mongodb" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id

    tags = {
      "Name" = "mongodb-Andre"
    }
    key_name = aws_key_pair.slacko-sshkey.id
    user_data = file("${path.module}/files/mongodb.sh")
}

resource "aws_security_group" "allow-slacko" {
    name = "allow_ssh_http"
    description = "allow ssh and http port"
    vpc_id = var.vpc_id

    ingress =[
     {
      description = "Allow SSH"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []	
      security_groups = []
      self = null
     },
     {
      description = "Allow http"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = null
     }
    ]


    egress = [
     {
      description = "Allow all"
      from_port = 0
      to_port = 0
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = null
     }
    ]

    tags = {
      "Name" = "allow_ssh_http"
    }
}


resource "aws_security_group" "allow-mongodb" {
    name = "allow_mongodb"
    description = "allow Momngodb"
    vpc_id = var.vpc_id

    ingress =[
     {
      description = "Allow mongodb"
      from_port = 27017
      to_port = 27017
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = null
     }
    ]


    egress = [
     {
      description = "Allow all"
      from_port = 0
      to_port = 0
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = null
     }
    ]

    tags = {
      "Name" = "allow_mongodb"
    }
}

resource "aws_network_interface_sg_attachment" "mongodb-sg" {
    security_group_id = aws_security_group.allow-mongodb.id
    network_interface_id = aws_instance.mongodb.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "slacko" {
    security_group_id = aws_security_group.allow-slacko.id
    network_interface_id = aws_instance.slacko-app.primary_network_interface_id
}

resource "aws_route53_zone" "slacko_zone" {
    name = "iaac0506.com.br"
    vpc {
        vpc_id = var.vpc_id 
    }
}

resource "aws_route53_record" "mongodb" {
    zone_id = aws_route53_zone.slacko_zone.id
    name = "mongodb.iaac0506.com.br"
    type = "A"
    ttl = "300"
    records = [aws_instance.mongodb.private_ip]
}


