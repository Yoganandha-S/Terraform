provider "aws" {
  region = "ap-southeast-1"
}

# VPC and Networking (unchanged from your original)
resource "aws_vpc" "non_prod_dataplane_singapore" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "singapore_public_subnet" {
  vpc_id                  = aws_vpc.non_prod_dataplane_singapore.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
}

resource "aws_subnet" "singapore_private_subnet_1" {
  vpc_id                  = aws_vpc.non_prod_dataplane_singapore.id
  cidr_block              = var.private_subnet_cidr_1
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false
}

resource "aws_subnet" "singapore_private_subnet_2" {
  vpc_id                  = aws_vpc.non_prod_dataplane_singapore.id
  cidr_block              = var.private_subnet_cidr_2
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.non_prod_dataplane_singapore.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.singapore_public_subnet.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.non_prod_dataplane_singapore.id
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.singapore_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.non_prod_dataplane_singapore.id
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.singapore_private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.singapore_private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# EKS Cluster using existing IAM roles
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.0"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = aws_vpc.non_prod_dataplane_singapore.id
  subnet_ids      = [aws_subnet.singapore_private_subnet_1.id, aws_subnet.singapore_private_subnet_2.id]
  enable_irsa     = true

  # Use existing IAM roles
  create_iam_role = false
  iam_role_arn    = var.cluster_role_arn

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # EKS Add-ons (compatible with 1.32)
  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  cluster_enabled_log_types = var.cluster_enabled_log_types
}

# Node Group with your specific SSH key
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "eks-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [aws_subnet.singapore_private_subnet_1.id, aws_subnet.singapore_private_subnet_2.id]

  instance_types = [var.node_instance_type]
  
  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  labels = {
    app = "true"
  }

  remote_access {
    ec2_ssh_key               = var.key_name
    source_security_group_ids = [module.eks.node_security_group_id]
  }

  # Ensure the addons are ready before node group creation
  depends_on = [
    module.eks.cluster_addons
  ]
}