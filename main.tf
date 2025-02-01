# Create a VPC
resource "aws_vpc" "Terraform-vpc" {
  cidr_block = var.vpc-cidr
}

# Create a Subnet 1
resource "aws_subnet" "Terraform_subnet-1" {
  vpc_id                  = aws_vpc.Terraform-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

}

# Create a Subnet 2
resource "aws_subnet" "Terraform_subnet-2" {
  vpc_id                  = aws_vpc.Terraform-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Create a Internet_gateway for VPC
resource "aws_internet_gateway" "Terrafor_igw" {
  vpc_id = aws_vpc.Terraform-vpc.id

  tags = {
    Name = "main_igw"
  }

}

# AWS_ROUTE_TABLE FOR INTERNER ACCESS
resource "aws_route_table" "Terraform_route_table" {
  vpc_id = aws_vpc.Terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terrafor_igw.id
  }
}

# AWS_ROUTE_TABLE ASSOCIATION WITH SUBNET 1
resource "aws_route_table_association" "association-1" {
  subnet_id      = aws_subnet.Terraform_subnet-1.id
  route_table_id = aws_route_table.Terraform_route_table.id
}

# AWS_ROUTE_TABLE ASSOCIATION WITH SUBNET 2
resource "aws_route_table_association" "association-2" {
  subnet_id      = aws_subnet.Terraform_subnet-2.id
  route_table_id = aws_route_table.Terraform_route_table.id
}

# CREATE SECURITY_GROUP TO ALLOW INBOUND AND OUTBOUND TRAFFIC
resource "aws_security_group" "Terra_sg" {
  name        = "allow_tlsWeb-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.Terraform-vpc.id

  tags = {
    Name = "Terraform-SG1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4-1" {
  security_group_id = aws_security_group.Terra_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4-2" {
  security_group_id = aws_security_group.Terra_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 80
}



resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.Terra_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# CRATE S3 BUCKET
resource "aws_s3_bucket" "DevOpsshubhtaydeterra" {
  bucket = "terrashubhamcode"
}


resource "aws_s3_bucket_ownership_controls" "terra-owner" {
  bucket = aws_s3_bucket.DevOpsshubhtaydeterra.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform-pulic_access" {
  bucket = aws_s3_bucket.DevOpsshubhtaydeterra.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "terraform_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.terra-owner,
    aws_s3_bucket_public_access_block.terraform-pulic_access,
  ]

  bucket = aws_s3_bucket.DevOpsshubhtaydeterra.id
  acl    = "public-read"
}

# CREATE AWS_EC2_INSTANCE 1 AND ATTACHED USERDATA1 TO EC2
resource "aws_instance" "Terraform-instance-1" {
  ami                    = "ami-0c614dee691cbbf37"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Terra_sg.id]
  subnet_id              = aws_subnet.Terraform_subnet-1.id
  user_data              = base64encode(file("userdata.sh"))

  tags = {
    Name = "terraform-project"
  }
}

# CREATE AWS_EC2_INSTANCE 2 AND ATTACHED USERDATA2 TO EC2
resource "aws_instance" "Terraform-instance-2" {
  ami                    = "ami-0c614dee691cbbf37"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Terra_sg.id]
  subnet_id              = aws_subnet.Terraform_subnet-2.id
  user_data              = base64encode(file("userdata1.sh"))

  tags = {
    Name = "terraform-project-2"
  }
}

# CREATE APPLICATION LOAD BALANCER TO DISTRIBUTE THE TRAFFIC ACROSS TO EC2 INSTNACE
resource "aws_lb" "terraform-alb" {
  name               = "alb-terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Terra_sg.id]
  subnets            = [aws_subnet.Terraform_subnet-1.id, aws_subnet.Terraform_subnet-2.id]


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "terra-tg" {
  name     = "terraform-project-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Terraform-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "target-attach" {
  target_group_arn = aws_lb_target_group.terra-tg.arn
  target_id        = aws_instance.Terraform-instance-1.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "target-attach2" {
  target_group_arn = aws_lb_target_group.terra-tg.arn
  target_id        = aws_instance.Terraform-instance-2.id
  port             = 80
}

resource "aws_lb_listener" "listner-alb" {
  load_balancer_arn = aws_lb.terraform-alb.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terra-tg.arn
  }
}

# TO ACCESS THE ALB DNS NAME 
output "loadbalancer" {
  value = aws_lb.terraform-alb.dns_name

}