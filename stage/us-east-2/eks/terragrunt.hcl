locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.region_vars.locals.aws_region
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=17.19.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    vpc_id  = "fake-vpc-id"
    subnets = ["fake-subnet-id"]
  }
}

inputs = {
  cluster_name    = "eks-cluster-${local.env}"
  cluster_version = "1.21"

  vpc_id  = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.private_subnets

  worker_groups = [
    {
      name                          = "spot-group"
      instance_type                 = "t3a.medium"
      spot_max_price                = "0.04"
      spot_price                    = "0.02"
      asg_desired_capacity          = 3
      asg_max_size                  = 5
      kubelet_extra_args            = "--node-labels=node.kubernetes.io/lifecycle=spot"
    },
    {
      name                 = "on-demand-group"
      instance_type        = "t3a.small"
      asg_desired_capacity = 3
      asg_max_size         = 5
      kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=spot"
    }
  ]

}
