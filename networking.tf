data "aws_vpc" "default" {
  default = true
}

resource "aws_vpc" "custom" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "project04-custom"
  }
}

moved {
  from = aws_subnet.allowed
  to   = aws_subnet.private1
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.custom.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name   = "subnet-custom-vpc"
    Access = "Private"
  }
}


# For documintatioin not acvtivly used
resource "aws_subnet" "not_allowed" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.128.0/24"
  tags = {
    Name = "subnet-default-vpc"
  }
}
