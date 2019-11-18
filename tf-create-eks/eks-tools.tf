########################################################################################################################
# EKS Tools Resources
#  * Cluster Autoscaler
#  * Horizontal Pod Autoscaling
#  * Kubernetes Dashboard
########################################################################################################################

#########################################
############## Install Helm #############
#########################################

resource "null_resource" "install-helm" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 120
      kubectl apply -f ${path.module}/files/helm-rbac.yaml --kubeconfig=${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig
      helm init --service-account tiller --kubeconfig ${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig
      sleep 120
    EOT
  }

  depends_on = [
    "local_file.kubeconfig",
    "aws_autoscaling_group.eks-cluster",
  ]
}

#########################################
########### Cluster AutoScaler ##########
#########################################

resource "null_resource" "cluster-autoscaling" {
  count = "${var.enable_autoscaler}"

  provisioner "local-exec" {
    command = "helm install --namespace kube-system stable/cluster-autoscaler --name cluster-autoscaler --set autoDiscovery.clusterName=${var.cluster_name} --set awsRegion=${var.region} --set sslCertPath=/etc/ssl/certs/ca-bundle.crt --set rbac.create=true --kubeconfig ${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig"
  }

  depends_on = ["null_resource.install-helm"]
}

###########################################
########### Kubernetes Dashboard ##########
###########################################

resource "null_resource" "kubernetes-dashboard" {
  count = "${var.enable_dashboard}"

  provisioner "local-exec" {
    command = "helm install --namespace kube-system stable/kubernetes-dashboard --name dashboard --kubeconfig=${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig"
  }

  depends_on = ["null_resource.install-helm"]
}

resource "null_resource" "kubernetes-dashboard-external-elb" {
  count = "${var.enable_dashboard-elb}"

  provisioner "local-exec" {
    command = "helm install ${path.module}/files/dashboard-elb --name dashboard-elb --kubeconfig=${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig"
  }

  depends_on = ["null_resource.install-helm"]
}

#################################################
########### Horizontal Pod Autoscaling ##########
#################################################

resource "null_resource" "horizontal-pod-autoscaling" {
  count = "${var.enable_hpa}"

  provisioner "local-exec" {
    command = "helm install --namespace kube-system stable/metrics-server --name metrics-server --kubeconfig=${var.local_path}/${var.customer}-${var.cluster_name}-kubeconfig"
  }

  depends_on = ["null_resource.install-helm"]
}
