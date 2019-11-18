###############################################################################################################################
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
###############################################################################################################################

resource "aws_iam_role" "eks-cluster-node" {
  name = "${var.cluster_name}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}

resource "aws_iam_policy" "additional_node_policy" {
  name        = "${var.cluster_name}AdditionalEKSNodesPolicy"
  path        = "/"
  description = "Additional access rights for ${var.cluster_name} EKS nodes"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AdditionalEKSNodesPolicy" {
  policy_arn = "${aws_iam_policy.additional_node_policy.arn}"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}

resource "aws_iam_instance_profile" "eks-cluster-node" {
  name = "${var.cluster_name}-node"
  role = "${aws_iam_role.eks-cluster-node.name}"
}

resource "aws_security_group" "eks-cluster-node" {
  name        = "${var.cluster_name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "CreatedBy", "Terraform",
     "Name", "${var.cluster_name}-node",
     "Environment", "${var.environment}",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-cluster-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-cluster-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-cluster-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-node-ingress-hpa" {
  description              = "Allow worker Kubelets and pods to receive communication for using HPA"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-cluster-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port                  = 443
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.k8s_version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

########################################################################################
# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
########################################################################################
locals {
  eks-cluster-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

resource "aws_launch_configuration" "eks-cluster" {
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.eks-cluster-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "${var.instance_type}"
  name_prefix                 = "${var.cluster_name}-node"
  security_groups             = ["${aws_security_group.eks-cluster-node.id}"]
  user_data_base64            = "${base64encode(local.eks-cluster-node-userdata)}"
  key_name                    = "${var.ssh_key_name}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = "${var.root_volume_size}"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["image_id"]
  }
}

resource "aws_autoscaling_group" "eks-cluster" {
  desired_capacity     = "${var.min_nodes}"
  launch_configuration = "${aws_launch_configuration.eks-cluster.id}"
  max_size             = "${var.max_nodes}"
  min_size             = "${var.min_nodes}"
  name                 = "${var.cluster_name}-node"
  vpc_zone_identifier  = ["${var.worker_subnets}"]

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-node"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      value               = "owned"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/cluster-autoscaler/enabled"
      value               = ""
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
      value               = ""
      propagate_at_launch = true
    },
  ]

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }
}

#############################
# SSH Access to Worker nodes
#############################
resource "aws_security_group_rule" "ssh_to_nodes" {
  type              = "ingress"
  security_group_id = "${aws_security_group.eks-cluster-node.id}"
  cidr_blocks       = ["${var.ssh_access_pool}"]
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  description       = "SSH from VPN"
}
