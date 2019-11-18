# EKS Getting Started Guide Configuration

Here is the [full original configuration](https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html)


# tf-module-eks

A terraform module to create a managed Kubernetes cluster on AWS EKS.
Available through the [Terraform registry](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws).  
Inspired by and adapted from [this doc](https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html)
and its [source code](https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/eks-getting-started).  
Read the [AWS docs on EKS to get connected to the k8s dashboard](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html).  

## Prerequisites
* Install [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
* Install [terraform](https://www.terraform.io/intro/getting-started/install.html)

## Assumptions

* You want to create an EKS cluster and an autoscaling group of workers for the cluster.
* You want these resources to exist within security groups that allow communication and coordination. These can be user provided or created within the module.
* You've created a Virtual Private Cloud (VPC) and subnets where you intend to put the EKS resources.
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl) (>=1.10) and [`helm`](https://helm.sh/docs/using_helm/#installing-the-helm-client) are installed and configured on your shell's PATH.
* AWS provider version has to be bigger than "2.7.0" To enforce add a `version` constraint: [Example](https://www.terraform.io/docs/providers/aws/guides/version-2-upgrade.html#provider-version-configuration)
* AWS CLI version has to be later than 1.16.155. [Upgrade Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html). The usage of `aws-iam-authenticator` is needed when using a release prior to v0.3.0.

## Important
It is highly recommended to always pull an official release and not `latest`.  
See the below example to use a specific release (`source = "...git?ref=v0.2.0`).

---

## Usage example

This module should be declared as a module in your main manifest folder.


How to declare from the state manifest:

```hcl
module "aws_eks_cluster" {
  source = "git::ssh://git@bitbucket.org/emindsys/tf-module-eks.git?ref=v0.2.0"
  
  region                      = "${var.aws_region}"
  profile                     = "${var.aws_profile}"
  environment                 = "dev"
  customer                    = "${var.customer}"
  cluster_name                = "${var.cluster_name}"
  ssh_key_name                = "${var.eks_key_name}"
  ssh_access_pool             = ["${data.terraform_remote_state.mgmt_account.mgmt_vpc_cidr_block}"]
  vpc_id                      = "${module.dev_vpc.vpc_id}"
  worker_subnets              = "${module.dev_vpc.private_subnets_ids}"
  public_subnets              = "${module.dev_vpc.public_subnets_ids}"
  cluster_enabled_log_types   = ["api","audit","authenticator","controllerManager","scheduler"]
  
  optional_tags = [
    {
      key                 = "Monitored"
      value               = "true"
      propagate_at_launch = true
    }
  ]
}

  
```

# Description of the variables: #

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| environment | Environment short name, eg: dev, stage, prod | string | - | yes |
| region | AWS Region to be used | string | - | yes |
| cluster_name | Full name of the cluster | string | - | yes |
| profile | Set the profile name if you want to use module with an AWS profile | string | - | yes |
| instance_type | Instance type used for Kubernetes workers | string | `m5.large` | no |
| ssh_key_name | Existent SSH key name used for Kubernetes workers | string | - | yes |
| root_volume_size | Size for root volume of the Kubernetes workers | string | `50` | no |
| min_nodes | Minimum number of Kubernetes workers | string | `2` | no |
| max_nodes | Maximum number of Kubernetes workers | string | `10` | no |
| vpc_id | Id of the VPC where the Kubernetes cluster will be deployed | string | - | yes |
| worker_subnets | Private subnets for your worker nodes | list | - | yes |
| public_subnets | Public subnets for Kubernetes to create internet-facing load balancers within | list | - | no |
| ssh_access_pool | IP range allowed to SSH on Kubernetes workers | string | `["0.0.0.0/0"]` | yes |
| bastion_role | Role ARN for an EC2 instance that will have full access to EKS cluster | string | - | no |
| jenkins_role | Role ARN for a Jenkins instance that will have access to EKS cluster | string | - | no |
| enable_autoscaler | If set to true, enable Cluster Autoscaler | string | `true` | no |
| enable_hpa | If set to true, enable Horizontal Pod Autocaling | string | `false` | no |
| enable_dashboard | If set to true, enable Kubernetes Dashboard | string | `false` | no |
| enable_dashboard-elb | If set to true, creates an external ELB for Dashboard | string | `false` | no |
| optional_tags | A list of additional tags in explicit format to add to Autoscaling Group | list | - | no |
| private_endpoint | If set to true, enables Private endpoint access | string | `false` | no |
| public_endpoint | If set to true, enables Public endpoint access | string | `true` | no |
| cluster_enabled_log_types | A list of the desired control plane logging to enable. For more information, see [Amazon EKS Control Plane Logging Documentation](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | list | [] | no |
| local_path | Path to save local files | string | `/tmp` | no |

## Outputs

| Name | Description |
|------|-------------|
| config_map_aws_auth | Config Map used to allow worker nodes to join the cluster via AWS IAM role authentication |
| kubeconfig | Configuration for kubectl |
| eks_node_sg_id | The security group id of the nodes |
| eks_cluster_sg_id | The security group id of the eks cluster (master nodes) |
| eks_node_autoscaling_group_id | The node's autoscaling group id |
