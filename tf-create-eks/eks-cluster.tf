#######################################################################################################################
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#######################################################################################################################

resource "aws_iam_role" "eks-cluster" {
  name = "${var.cluster_name}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-cluster.name}"
}

resource "aws_security_group" "eks-cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    CreatedBy = "Terraform"
    Name      = "${var.cluster_name}-cluster"
  }
}

resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-cluster.id}"
  source_security_group_id = "${aws_security_group.eks-cluster-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

############################################################################
# Attach additional IAM policy for using Load Balancers & Cluster Autoscaler
############################################################################

resource "aws_iam_policy" "additional_eks_policy" {
  name        = "${var.cluster_name}AdditionalEKSClusterPolicy"
  path        = "/"
  description = "Additional access rights for ${var.cluster_name} EKS cluster"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ec2:DescribeAccountAttributes"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AdditionalEKSClusterPolicy" {
  policy_arn = "${aws_iam_policy.additional_eks_policy.arn}"
  role       = "${aws_iam_role.eks-cluster.name}"
}

#############################################################
# Allow inbound traffic from Management VPC to the Kubernetes
#############################################################
resource "aws_security_group_rule" "eks-cluster-ingress-vpn-https" {
  cidr_blocks       = ["${var.ssh_access_pool}"]
  description       = "Allow VPN to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "eks-cluster" {
  name                      = "${var.cluster_name}"
  role_arn                  = "${aws_iam_role.eks-cluster.arn}"
  version                   = "${var.k8s_version}"
  enabled_cluster_log_types = "${var.cluster_enabled_log_types}"

  vpc_config {
    security_group_ids      = ["${aws_security_group.eks-cluster.id}"]
    subnet_ids              = ["${var.worker_subnets}", "${var.public_subnets}"]
    endpoint_private_access = "${var.private_endpoint}"
    endpoint_public_access  = "${var.public_endpoint}"
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy",
  ]
}

########################################################################
# Allow worker nodes to join the cluster via AWS IAM role authentication
########################################################################

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks-cluster-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.jenkins_role}
      username: jenkins:{{EC2PrivateDNSName}}
      groups:
        - system:masters
    - rolearn: ${var.bastion_role}
      username: bastion:{{EC2PrivateDNSName}}
      groups:
        - system:masters

CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks-cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks-cluster.certificate_authority.0.data}
  name: "${aws_eks_cluster.eks-cluster.arn}"
contexts:
- context:
    cluster: "${aws_eks_cluster.eks-cluster.arn}"
    user: "${aws_eks_cluster.eks-cluster.arn}"
  name: ${var.customer}-${var.cluster_name}
current-context: ${var.customer}-${var.cluster_name}
kind: Config
preferences: {}
users:
- name: "${aws_eks_cluster.eks-cluster.arn}"
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      env:
      - name: "AWS_PROFILE"
        value: "${var.profile}"
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster_name}"
KUBECONFIG
}

resource "local_file" "kubeconfig" {
  content  = "${local.kubeconfig}"
  filename = "${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig"
}

resource "local_file" "config-map" {
  content  = "${local.config_map_aws_auth}"
  filename = "${var.local_path}/${var.customer}-${var.cluster_name}-config_map_aws_auth.yaml"

  provisioner "local-exec" {
    command = "kubectl apply -f ${var.local_path}/${var.customer}-${var.cluster_name}-config_map_aws_auth.yaml --kubeconfig=${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig"
  }

  depends_on = ["local_file.kubeconfig"]
}
