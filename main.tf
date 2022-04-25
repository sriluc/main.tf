terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "4.11.0"
        }
    }
}


provider "aws" {
  profile = "default"
  region = "eu-west-1"
}


resource "aws_vpc" "dev_vpc" {
    cidr_block = "10.10.0.0/16"
    instance_tenancy = "default"
}

# Public Subnet Setup for Front end

resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.dev_vpc.id
}

resource "aws_subnet" "frontend_subnet" {
    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.10.1.0/24"
}

resource "aws_route_table" "FrontendRT" {
    vpc_id = aws_vpc.dev_vpc.id
    route {
        gateway_id = aws_internet_gateway.IGW.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "FrontendRTA" {
    subnet_id = aws_subnet.frontend_subnet.id
    route_table_id = aws_route_table.FrontendRT.id
}

# Setup for Backend

resource "aws_subnet" "backend_subnet" {
    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.10.2.0/24"
}

resource "aws_eip" "natIP" {
    vpc = true
}

resource "aws_nat_gateway" "NGW_BE" {
    allocation_id = aws_eip.natIP.id
    subnet_id = aws_subnet.backend_subnet.id
}

resource "aws_route_table" "BackendRT" {
    vpc_id = aws_vpc.dev_vpc.id

    route {
        gateway_id = aws_nat_gateway.NGW_BE.id
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "BackendRTA" {
    subnet_id = aws_subnet.backend_subnet.id
    route_table_id = aws_route_table.BackendRT.id
}

# Network interface for Database Subnet

resource "aws_security_group" "DatabaseSG" {
    name = "databaseSG"
    description = "Security group to allow connectivity to database subnet only via Backend Subnet"
    vpc_id = aws_vpc.dev_vpc.id

    ingress {
        description = "allow incoming connections on mysql default port"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.10.2.0/24"]
    }

    egress {
        description = "allow outgoing connections on mysql default port"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.10.2.0/24"]
    }

}


# Setup for database subnet

resource "aws_subnet" "database_subnet" {
    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.10.3.0/24"
    
}

resource "aws_eip" "natIPDB" {
    vpc = true
}

resource "aws_nat_gateway" "NGW_DB" {
    allocation_id = aws_eip.natIPDB.id
    subnet_id = aws_subnet.database_subnet.id
}

resource "aws_route_table" "DatabaseRT" {
    vpc_id = aws_vpc.dev_vpc.id

    route {
        gateway_id = aws_nat_gateway.NGW_DB.id
        cidr_block = "10.10.2.0/24"
    } 
}

resource "aws_route_table_association" "DatabaseRTA" {
    subnet_id = aws_subnet.database_subnet.id
    route_table_id = aws_route_table.DatabaseRT.id
}
