# AWS Variables
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Aws default region"
}

# VPC Variables
variable "aws_vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/20"
}

variable "aws_enable_vpn_gateway" {
  description = "Enable a VPN gateway in your VPC."
  type        = bool
  default     = false
}

variable "aws_enable_nat_gateway" {
  description = "Enable a nat gateway in the public subnets of VPC"
  type        = bool
  default     = true
}

variable "aws_public_subnet_count" {
  description = "Number of public subnets in VPC."
  type        = number
  default     = 2
}

variable "aws_private_subnet_count" {
  description = "Number of private subnets in VPC."
  type        = number
  default     = 2
}

# locals {
#     public_cidrs = [
#     for i in range(var.aws_public_subnet_count) : cidrsubnet(var.aws_vpc_cidr_block, 4, i)
#   ]

#     private_cidrs = [
#     for i in range(var.aws_public_subnet_count) : cidrsubnet(var.aws_vpc_cidr_block, 4, i)
#   ]
# }

# variable "aws_public_subnet_cidr_blocks" {
#   description = "Available cidr blocks for public subnets in VPC."
#   type        = list(string)
#   default = [
#     "10.0.1.0/24",
#     "10.0.2.0/24",
#     "10.0.3.0/24",
#   ]

# }

# variable "aws_private_subnet_cidr_blocks" {
#   description = "Available cidr blocks for private subnets in VPC."
#   type        = list(string)
#   default = [
#     "10.0.10.0/24",
#     "10.0.11.0/24",
#     "10.0.12.0/24",
#   ]
# }

# Instance variables
variable "aws_frontend_instance_ami" {
  type        = string
  default     = "ami-0ae8f15ae66fe8cda"
  description = "Amazon Linux 2023 AMI."
}

variable "aws_frontend_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "t2 micro free eligible tier."
}

variable "aws_frontend_instance_count" {
  description = "Number of instances to provision."
  type        = number
  default     = 2
}

variable "aws_backend_instance_ami" {
  type        = string
  default     = "ami-0ae8f15ae66fe8cda"
  description = "Amazon Linux 2023 AMI."
}

variable "aws_backend_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "t2 micro free eligible tier."
}

variable "aws_backend_instance_count" {
  description = "Number of instances to provision."
  type        = number
  default     = 1
}


variable "aws_bastion_instance_ami" {
  type        = string
  default     = "ami-0ae8f15ae66fe8cda"
  description = "Amazon Linux 2023 AMI."
}

variable "aws_bastion_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "t2 micro free eligible tier."
}

# RDS variables

variable "db_admin_storage" {
  type        = number
  description = "Db instance storage capacity"
  default     = 20
}

variable "db_storage" {
  type        = number
  description = "Db instance storage capacity"
  default     = 20
}

variable "db_engine" {
  type        = string
  description = "Db instance engine"
  default     = "mysql"
}

variable "db_engine_version" {
  type        = string
  description = "Db engine version"
  default     = "8.0.35"
}


variable "db_instance_type" {
  type        = string
  description = "Db isntance free eligible tier 2vcpu 1GiB 2085 Mbps"
  default     = "db.t3.micro"
}

variable "db_admin_username" {
  type        = string
  description = "Db isntance admin user"
}

variable "db_admin_passwd" {
  type        = string
  description = "Db instance admin password"
}

# Resource tags
variable "aws_resource_tags" {
  type        = map(string)
  description = "Tags to be applied to each resource this TF configuration creates."
  default = {
    project     = "project-alpha"
    version     = "1.2"
    environment = "prod"
    owner       = "dz@dzcol.com"
  }

  validation {
    condition     = length(var.aws_resource_tags["project"]) <= 16 && length(regexall("[^a-zA-Z0-9-]", var.aws_resource_tags["project"])) == 0
    error_message = "The project tag must be no more than 16 characters, and only contain letters, numbers, and hyphens."

  }

  validation {
    condition     = length(var.aws_resource_tags["environment"]) <= 4 && length(regexall("[^a-zA-Z0-9-]", var.aws_resource_tags["environment"])) == 0
    error_message = "The environment tag must be no more than 8 characters, and only contain letters, numbers, and hyphens."

  }

}

# aws configurations

variable "aws_bucket" {
  type        = string
  description = "S3 bucket containing state file"
}

variable "aws_bucket_key" {
  type        = string
  description = "S3 bucket containing state file"
}