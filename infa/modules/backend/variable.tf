variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "default_tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.32.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    cidr              = string
    availability_zone = string
  }))
  default = {
    "pub-subnet-1" = {
      cidr              = "172.32.0.0/24"
      availability_zone = "ap-northeast-1a"
    }
    "pub-subnet-2" = {
      cidr              = "172.32.1.0/24"
      availability_zone = "ap-northeast-1c"
    }
  }
}

variable "private_subnets" {
  description = "Map of private subnet configurations"
  type = map(object({
    cidr              = string
    availability_zone = string
  }))
  default = {
    "priv-subnet-1" = {
      cidr              = "172.32.2.0/24"
      availability_zone = "us-east-1a"
    }
    "priv-subnet-2" = {
      cidr              = "172.32.3.0/24"
      availability_zone = "us-east-1c"
    }
  }
}