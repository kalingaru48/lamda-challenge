# Initializing the Project with Terraform

To initialize your Terraform project with s3 backend configuration, you can use the following command:

```sh
terraform init -backend-config=backend.hcl
```

This command initializes the Terraform working directory and configures the backend settings as specified in the `backend.hcl` file.

Make sure your `backend.hcl` file contains the necessary backend configuration details.

Example `backend.hcl`:

```hcl
terraform {
  backend "s3" {
    bucket = "kalterraformbackend"
    key    = "lab/dev/statefile.tfstate"
    encrypt      = true  
    use_lockfile = true  #S3 native locking
    region = "us-east-1"
  }
}
```

This configuration will set up the Terraform backend to use an S3 bucket for storing the Terraform state.

Next terraform plan to see what infra resource going to becreated 
```sh
terraform plan
```

Deploy infra resources
```sh
terraform apply
```
Clearn up resources
```sh
terraform destroy
```