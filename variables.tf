variable "region" {
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  default = "10.2.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.2.16.0/20"
}

variable "private_subnet_cidr_1" {
  default = "10.2.32.0/20"
}

variable "private_subnet_cidr_2" {
  default = "10.2.48.0/20"
}

variable "availability_zone_1" {
  default = "ap-southeast-1a"
}

variable "availability_zone_2" {
  default = "ap-southeast-1b"
}

variable "cluster_name" {
  default = "dev-dp-eks-cluster-singapore"
}

variable "cluster_version" {
  default = "1.32"
}

variable "cluster_role_arn" {
  description = "ARN of existing EKS cluster IAM role"
}

variable "node_role_arn" {
  description = "ARN of existing EKS node IAM role"
}

variable "node_instance_type" {
  default = "t3.medium"
}

variable "node_desired_capacity" {
  default = 2
}

variable "node_max_capacity" {
  default = 3
}

variable "node_min_capacity" {
  default = 2
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair for SSH access"
}

variable "cluster_enabled_log_types" {
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}