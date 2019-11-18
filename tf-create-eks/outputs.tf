#######################################################################################################################
# Outputs
#######################################################################################################################

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

output "eks_node_sg_id" {
  value = "${aws_security_group.eks-cluster-node.id}"
}

output "eks_cluster_sg_id" {
  value = "${aws_security_group.eks-cluster.id}"
}

output "eks_node_autoscaling_group_id" {
  value = "${aws_autoscaling_group.eks-cluster.id}"
}

output "eks_launch_configuration_id" {
  value = "${aws_launch_configuration.eks-cluster.id}"
}