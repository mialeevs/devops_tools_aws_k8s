variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The Default AWS region"
}


variable "ec2_instance_name" {
  type        = string
  default     = "DevSecOps_Node"
  description = "The Default AWS EC2 name"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.xlarge" # CompleteStack
  description = "The default instance type for single K8S node"
}

variable "ec2_ami_id" {
  type        = string
  default     = "ami-0c7217cdde317cfec"
  description = "The default one for Virginia region"
}

# Define a map for the required ports and their descriptions
variable "ingress_ports" {
  type = map(object({
    from_port = number
    to_port   = number
    protocol  = string
  }))

  default = {
    ssh      = { from_port = 22, to_port = 22, protocol = "tcp" }
    nodeport = { from_port = 30000, to_port = 32767, protocol = "tcp" }
  }
}


variable "my_ip" {}
