##################################
# Subnet Validation
##################################
data "aws_vpc" "default" {
  default = true
}
data "aws_subnet" "input" {
  for_each = toset(var.subnet_ids)
  id       = each.value

  lifecycle {
    postcondition {
      condition     = self.vpc_id != data.aws_vpc.default.id
      error_message = <<-EOT
        The following subnet is part of the default VPC:

        Name = ${self.tags.Name}
        ID   = ${self.id}

        Please do not deploy RDS instances in the default VPC.
        EOT
    }

    postcondition {
      condition     = can(lower(self.tags.Access) == "private")
      error_message = <<-EOT
        The following subnet is not marked as private:

        Name = ${self.tags.Name}
        ID   = ${self.id}

        Please ensure that the subnet is properly tagged by adding the following tags:
        1. Access = "private"
        EOT
    }
  }
}


##################################
# Security Group Validation
##################################
