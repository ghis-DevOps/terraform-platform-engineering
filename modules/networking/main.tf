# VPC with 6 Subnets (3 Public, 3 Private)
resource "aws_vpc" "sandbox_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "webforx-sandbox-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.sandbox_vpc.id
  tags   = { Name = "webforx-igw" }
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.sandbox_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "us-east-1${element(["a", "b", "c"], count.index)}"
  map_public_ip_on_launch = true
  tags                    = { Name = "webforx-public-subnet-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}"
  tags              = { Name = "webforx-private-subnet-${count.index + 1}" }
}

# Gateway Endpoints for S3 and DynamoDB
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"
}

# Route 53 Private Hosted Zone for Internal Services
resource "aws_route53_zone" "internal_zone" {
  name = "internal.webforx.local"
  vpc {
    vpc_id = aws_vpc.sandbox_vpc.id
  }
}