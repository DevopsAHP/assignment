variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "my-cluster"
}

variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "key_pair_name" {
  description = "The name of the EC2 key pair for EKS nodes"
  default     = "k8"
}

