project_name = "esagirov-ce"
region       = "eu-west-1"
vpc_cidr     = "10.0.0.0/16"
tags = {
  ProjectName = "AWS-CE"
  Owner       = "Eldar Sagirov"
}

install_calico = true

argocd_workloads = {
  workloads = {
    path               = "envs/dev"
    repo_url           = "https://gitlab.dataart.com/da/deco/aws-eks-starter-argocd.git"
    add_on_application = false
  }
}