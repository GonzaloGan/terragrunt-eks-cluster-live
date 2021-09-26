locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region = local.region_vars.locals.aws_region
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=3.6.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  name = "eks-vpc-${local.env}"
  cidr = "10.0.0.0/16"


  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  enable_nat_gateway    = true
  single_nat_gateway    = true
  enable_dns_hostsnames = true

  tags = {
    "Name"                                                              = "eks-vpc-${local.env}"
    "kubernetes.io/cluster/eks_terragrunt_${local.region}_${local.env}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/eks_terragrunt_${local.region}_${local.env}" = "shared"
    "kubernetes.io/role/elb"                                            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks_terragrunt_${local.region}_${local.env}" = "shared"
    "kubernetes.io/role/internal-elb"                                   = "1"
  }

}
