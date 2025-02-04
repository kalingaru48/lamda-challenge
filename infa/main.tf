module "todo-api" {
  source = "./modules/backend"
  project_name = "todo"
  vpc_cidr = "172.32.0.0/16"
  public_subnets = {
    "pub-subnet-1" = {
      cidr              = "172.32.0.0/24"
      availability_zone = "us-east-1a"
    }
    "pub-subnet-2" = {
      cidr              = "172.32.1.0/24"
      availability_zone = "us-east-1b"
    }
  }
  private_subnets = {
    "priv-subnet-1" = {
      cidr              = "172.32.2.0/24"
      availability_zone = "us-east-1a"
    }
    "priv-subnet-2" = {
      cidr              = "172.32.3.0/24"
      availability_zone = "us-east-1b"
    }
  }
  
}

module "frontend" {
  source = "./modules/frontend"
  project_name = "todo"
  api_gateway_url = module.todo-api.api_gateway_url
  depends_on = [ module.todo-api ]
}