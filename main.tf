

provider "aws" {
  region  = "us-east-1"
  profile = "maureenc5"
}

#create a Linus instance

#resource "aws_instance" "maureen-tf-server" {
# instance_type = "t2.micro"
#  tags = {
#   Name = "Maureen-tf_Project_01"
#   }
# }

#Create a vpc
resource "aws_vpc" "maureen-tf-vpc" {
  cidr_block = "10.0.0.0/16"
  # instance_tenancy = "default"

  tags = {
    Name = "Maureen_Prod_VPC"
  }
}

# Create an internet gateway and reference to the vpc created
resource "aws_internet_gateway" "Maureen_prod_Igw" {
  vpc_id = aws_vpc.maureen-tf-vpc.id
  tags = {
    Name = "Maureen_Igw"
  }

}

#create a route table and reference to the vpc created
resource "aws_route_table" "Maureen_Prod_route_table" {
  vpc_id = aws_vpc.maureen-tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Maureen_prod_Igw.id
  }

  # route {
  #  ipv6_cidr_block        = "::/0"
  #  gateway_id = aws_internet_gateway.Maureen_prod_Igw.id
  #}

  tags = {
    Name = "Maureen_route_table"
  }
}

#Create a subnet in an avalability zone
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.maureen-tf-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Maureen_Prod_subnet"
  }
}

#Associate the subnet created with the route table create
resource "aws_route_table_association" "route_table_assn" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.Maureen_Prod_route_table.id
}

#Create a security group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.maureen-tf-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#Create a network interface with an ip in the subnet that was created
resource "aws_network_interface" "web_server_Maureen" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

#Assign an elastic IP to the network interface created
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web_server_Maureen.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.Maureen_prod_Igw]
}

#Create unbuntu server and install/enable apache2
resource "aws_instance" "maureen-web-server-instance" {
  ami               = "ami-053b0d53c279acc90"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "main.key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_Maureen.id
  }

  user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update
        sudo apt install apache2 -y
        sudo systemctl start apache2
        sudo bash  -c "echo your very first web server" > "/var/www/html/index.html"
        EOF

  tags = {
    Name = "Maureen-web_server_01"
  }
}


# resource "<provider>_<resource_type>" "name" {
#    config options....
#    key = "value"
#    key 2 = "another value"
#}
