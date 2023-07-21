# data "aws_ami" "eks" {
#   owners      = ["amazon"]
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amazon-eks-node-${module.eks_blueprints.eks_cluster_version}-*"]
#   }
# }

# data "aws_ami" "bottlerocket" {
#   owners      = ["amazon"]
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["bottlerocket-aws-k8s-${module.eks_blueprints.eks_cluster_version}-x86_64-*"]
#   }
# }

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
