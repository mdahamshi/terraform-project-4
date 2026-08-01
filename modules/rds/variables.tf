variable "project_name" {
  type        = string
  description = "The project name."
}


# DB config

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "The instance class used to create the RDS instance"
}



variable "storage_size" {
  type        = number
  default     = 10
  description = "The amount of storage to allocate to the RDS instance. Should be between 5GB and 10GB."
}

variable "engine" {
  type        = string
  default     = "postgres-latest"
  description = "Which engine to use for the RDS instance. Currently only postgres is supported."
}


variable "credentials" {
  type = object({
    username = string
    password = string
  })

  sensitive   = true
  description = "RDS username and password"
}
