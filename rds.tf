resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

module "database" {
  source = "./modules/rds"

  project_name = "project-04-rds-module"
  credentials = {
    username = "db-admin"
    password = "12A3a3"
  }
}
