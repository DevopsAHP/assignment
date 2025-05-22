resource "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_iam_role" "eks_node_role" {
  name = "eksNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  count      = 3
  role       = aws_iam_role.eks_node_role.name
  policy_arn = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ][count.index]
}

resource "aws_iam_instance_profile" "eks_node_role" {
  name = "eksNodeInstanceProfile"
  role = aws_iam_role.eks_node_role.name
}

resource "aws_launch_template" "eks_launch_template" {
  name_prefix   = "eks-node"
  key_name      = var.key_pair_name
  instance_type = "t3.medium"
  
  # Specify the Ubuntu 24.04 AMI ID
  image_id      = "ami-0039e9010be782f05"  # Ubuntu 24.04 AMI ID for EKS

  tag_specifications {
    resource_type = "instance"
    tags = {
      "Role"        = "eks-node"
      "Environment" = "dev"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      "Role"        = "eks-node"
      "Environment" = "dev"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.eks_launch_template.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.node_policies
  ]
}

# Create a LoadBalancer service for the EKS cluster
resource "kubernetes_service" "load_balancer" {
  metadata {
    name      = "api-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "api"
    }

    port {
      port        = 80
      target_port = 5005
    }

    type = "LoadBalancer"
  }
}

