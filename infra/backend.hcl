terraform {
  backend "s3" {
    bucket = "kalterraformbackend"
    key    = "lab/dev/statefile.tfstate"
    encrypt      = true  
    use_lockfile = true  #S3 native locking
    region = "us-east-1"
  }
}
