resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "tempkey"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./tempkey.pem"
  }
}

resource "aws_instance" "temp_ec2" {
  # ami           = "ami-0c7217cdde317cfec"
  # Below AMI is for Mumbai region
  ami           = var.ec2_ami_id
  instance_type = var.ec2_instance_type
  key_name      = "tempkey"


  tags = {
    Name = var.ec2_instance_name
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./${aws_key_pair.kp.key_name}.pem")
      host        = self.public_ip
    }
    source      = "install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./${aws_key_pair.kp.key_name}.pem")
      host        = self.public_ip
    }
    inline = [
      "chmod +x /tmp/install.sh",
      "/tmp/install.sh"

    ]
  }
  security_groups = [aws_security_group.main.name]
}



resource "aws_security_group" "main" {
  name        = "devops_sg"
  description = "Security group for DevOps tools server"

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ["${var.my_ip}/32"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
