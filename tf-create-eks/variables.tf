#######################################################################################################################
# Variables Configuration
#######################################################################################################################

variable "environment" {
  description = "Environment short name, eg: dev, stage, prod"
  type        = "string"
}

variable "cluster_name" {
  description = "Full name of the cluster"
  type        = "string"
}

variable "region" {
  description = "AWS Region to be used"
  type        = "string"
}

variable "profile" {
  description = "Set the profile name if you want to use module with an AWS profile"
  type        = "string"
}

variable "instance_type" {
  description = "Instance type used for Kubernetes workers"
  default     = "m5.large"
  type        = "string"
}

variable "ssh_key_name" {
  description = "Existent SSH key name used for Kubernetes workers"
  type        = "string"
}

variable "root_volume_size" {
  description = "Size for root volume of the Kubernetes workers"
  default     = "50"
  type        = "string"
}

variable "min_nodes" {
  description = "Minimum number of Kubernets workers"
  default     = "2"
  type        = "string"
}

variable "max_nodes" {
  description = "Maximum number of Kubernets workers"
  default     = "10"
  type        = "string"
}

variable "vpc_id" {
  description = "Id of the VPC where the Kubernetes cluster will be deployed"
  type        = "string"
}

variable "worker_subnets" {
  description = "Private subnets for your worker nodes"
  type        = "list"
}

variable "public_subnets" {
  description = "Public subnets for Kubernetes to create internet-facing load balancers within"
  type        = "list"
  default     = []
}

variable "ssh_access_pool" {
  description = "IP range allowed to SSH on Kubernetes workers"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "bastion_role" {
  description = "Role ARN for an EC2 instance that will have full access to EKS cluster"
  default     = ""
}

variable "jenkins_role" {
  description = "Role ARN for an Jenkins instance that will have access to EKS cluster"
  default     = ""
}

variable "enable_autoscaler" {
  description = "Enable Cluster autoscaler"
  default     = true
}

variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler"
  default     = true
}

variable "enable_dashboard" {
  description = "Enable Kubernetes Dashboard"
  default     = false
}

variable "enable_dashboard-elb" {
  description = "Enable ELB for Kubernetes Dashboard"
  default     = false
}

variable "customer" {
  description = "Customer name for kubenconfig easy identification"
}

variable "k8s_version" {
  description = "Worker node AMI Version of K8s to use"
  default     = "1.11"
}

variable "optional_tags" {
  type        = "list"
  description = "A list of additional tags in explicit format to add to Autoscaling Group."
  default     = []
}

variable "private_endpoint" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  default     = false
}

variable "public_endpoint" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = true
}

variable "cluster_enabled_log_types" {
  default     = []
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = "list"
}

variable "local_path" {
  description = "Path to save local files"
  default     = "/tmp"
}