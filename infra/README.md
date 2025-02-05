# Initializing the Project with Terraform

To initialize your Terraform project with a specific backend configuration, you can use the following command:

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

This configuration will set up the backend to use an S3 bucket for storing the Terraform state.
