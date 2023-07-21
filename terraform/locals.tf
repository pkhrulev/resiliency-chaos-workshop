locals {
  name   = var.project_name
  region = var.region

  node_group_name = "self-ondemand"

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = var.tags

  eks_user_groups = [
    "administrators"
  ]

  # application_teams = {
  #   team-eshop = {
  #     "labels" = {
  #       "appName"         = "eshop-team-app",
  #       "projectName"     = "project-eshop",
  #       "environment"     = var.environment,
  #       "istio-injection" = "enabled"
  #     }
  #     "quota" = {
  #       "requests.cpu"    = "30",
  #       "requests.memory" = "80Gi",
  #       "limits.cpu"      = "80",
  #       "limits.memory"   = "100Gi",
  #       "pods"            = "100",
  #       "secrets"         = "100",
  #       "services"        = "100"
  #     }

  #     manifests_dir = "./manifests-team-eshop"
  #     users         = [aws_iam_role.eks_access["eshop-team"].arn]
  #   }
  # }
}