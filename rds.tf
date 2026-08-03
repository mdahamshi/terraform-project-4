
module "database" {
  source = "./modules/rds"

  project_name = "project-04-rds-module"
  security_group_ids = [
    aws_security_group.compliant.id
  ]
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id,
  ]
  credentials = {
    username = "db-admin"
    password = "12A3a332"
  }
}


#terraform apply -target="aws_security_group.complaint" -target="aws_vpc_security_group_ingress_rule.db"
