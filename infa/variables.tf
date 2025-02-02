variable "aws_region" {
  type = string
  default = "us-west-2"
  
}

variable "aws_profile" {
  description = "The name of the profile used to deploy"
  type        = string
}

variable "default_tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "project_name" {
  type = string
  default = "task"
}