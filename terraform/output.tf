# Fetch EC2 Instances based on the Node Group tag
data "aws_instances" "node_group_instances" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.node_group.node_group_name]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/${aws_eks_cluster.eks.name}"
    values = ["owned"]
  }
}

output "node_instance_ips" {
  value = data.aws_instances.node_group_instances.public_ips
}

