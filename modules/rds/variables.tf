variable "project_name" {
  type        = string
  description = "The project name."
}


# DB config

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "The instance class used to create the RDS instance"

  validation {
    condition     = contains(["db.t3.micro"], var.instance_class)
    error_message = "Only db.t3.micro is allowed"
  }
}



variable "storage_size" {
  type        = number
  default     = 10
  description = "The amount of storage to allocate to the RDS instance. Should be between 5GB and 10GB."
  validation {
    condition     = var.storage_size > 5 && var.storage_size <= 10
    error_message = "DB storage between 5 and 10"
  }
}

variable "engine" {
  type        = string
  default     = "postgres-latest"
  description = "Which engine to use for the RDS instance. Currently only postgres is supported."

  validation {
    condition     = contains(["postgres-latest", "postgres-14"], var.engine)
    error_message = "DB engine must be psotgres-latest or postgres-14"
  }
}


variable "credentials" {
  type = object({
    username = string
    password = string
  })

  sensitive   = true
  description = "RDS username and password"

  validation {
    condition = (
      length(regexall("[a-zA-Z]+", var.credentials.password)) > 0
      && length(regexall("[0-9]+", var.credentials.password)) > 0
      && length(regexall("^[a-zA-Z0-9]{6,}$", var.credentials.password)) > 0
    )
    error_message = "Password must contain at least one character and 1 digit, and at least 6 characters long"
  }
}
