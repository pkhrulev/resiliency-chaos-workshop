resource "aws_iam_role" "eks_access" {
  for_each = toset(local.eks_user_groups)

  name               = "${local.name}-eks-${each.value}-access"
  assume_role_policy = data.aws_iam_policy_document.account_assume_role_policy.json

  inline_policy {
    name   = "policy"
    policy = data.aws_iam_policy_document.inline_policy.json
  }

  tags = local.tags
}

data "aws_iam_policy_document" "inline_policy" {
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:${local.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.name}"]
  }
}

data "aws_iam_policy_document" "account_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.17.0"

  cluster_name    = local.name
  cluster_version = "1.23"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets


  node_security_group_additional_rules = {
    ingress_nodes_karpenter_port = {
      description                   = "Cluster API to Nodegroup for Karpenter"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    },
    all_cluster_internal = {
      description                   = "Cluster API to Nodegroup for Karpenter"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    },
    all_nodes_internal = {
      description = "Cluster API to Nodegroup for Karpenter"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    all_cluster_outbound = {
      description = "Cluster API to Nodegroup for Karpenter"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    },
  }


  node_security_group_tags = {
    "karpenter.sh/discovery/${local.name}" = local.name
  }

  self_managed_node_groups = {
    self_mg_t3_zone_a = {
      node_group_name    = "${local.node_group_name}-a"
      launch_template_os = "amazonlinux2eks"
      max_size           = 3
      min_size           = 0
      desired_size       = 3
      subnet_ids         = [module.vpc.private_subnets.0]
      instance_type      = "t3.small"
      create_iam_role           = false                                         # Changing `create_iam_role=false` to bring your own IAM Role
      iam_role_arn              = aws_iam_role.self_managed_ng.arn              # custom IAM role for aws-auth mapping; used when create_iam_role = false
      iam_instance_profile_name = aws_iam_instance_profile.self_managed_ng.name # IAM instance profile name for Launch templates; used when create_iam_role = false
    }
    self_mg_t3_zone_b = {
      node_group_name    = "${local.node_group_name}-b"
      launch_template_os = "amazonlinux2eks"
      max_size           = 3
      min_size           = 0
      desired_size       = 0
      subnet_ids         = [module.vpc.private_subnets.1]
      instance_type      = "t3.small"
      create_iam_role           = false                                         # Changing `create_iam_role=false` to bring your own IAM Role
      iam_role_arn              = aws_iam_role.self_managed_ng.arn              # custom IAM role for aws-auth mapping; used when create_iam_role = false
      iam_instance_profile_name = aws_iam_instance_profile.self_managed_ng.name # IAM instance profile name for Launch templates; used when create_iam_role = false
    }
    self_mg_t3_zone_c = {
      node_group_name    = "${local.node_group_name}-c"
      launch_template_os = "amazonlinux2eks"
      max_size           = 3
      min_size           = 0
      desired_size       = 0
      subnet_ids         = [module.vpc.private_subnets.2]
      instance_type      = "t3.small"
      create_iam_role           = false                                         # Changing `create_iam_role=false` to bring your own IAM Role
      iam_role_arn              = aws_iam_role.self_managed_ng.arn              # custom IAM role for aws-auth mapping; used when create_iam_role = false
      iam_instance_profile_name = aws_iam_instance_profile.self_managed_ng.name # IAM instance profile name for Launch templates; used when create_iam_role = false
    }
  }

  platform_teams = {
    admin = {
      users = [aws_iam_role.eks_access["administrators"].arn]
    }
  }

  #application_teams = local.application_teams

  tags = local.tags
}

#---------------------------------------------------------------
# Custom IAM role for Self Managed Node Group
#---------------------------------------------------------------
data "aws_iam_policy_document" "self_managed_ng_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "self_managed_ng" {
  name                  = "self-managed-node-role"
  description           = "EKS Managed Node group IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.self_managed_ng_assume_role_policy.json
  path                  = "/"
  force_detach_policies = true
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]

  tags = local.tags
}

resource "aws_iam_instance_profile" "self_managed_ng" {
  name = "self-managed-node-instance-profile"
  role = aws_iam_role.self_managed_ng.name
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}



module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "aws-ce/app"
  
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_read_write_access_arns =[aws_iam_role.self_managed_ng.arn]

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.32.1"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  enable_argocd         = false
  argocd_manage_add_ons = false # Indicates that ArgoCD is responsible for managing/deploying add-ons
  # argocd_applications = merge(
  #   {
  #     addons = {
  #       path               = "chart"
  #       repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
  #       add_on_application = true
  #     }
  #   },
  #   var.argocd_workloads
  # )

  # Add-ons
  enable_cluster_autoscaler = true
  # enable_karpenter                             = false
  # enable_metrics_server                        = true
  # enable_prometheus                            = true
  enable_vpa                                   = true
  # enable_argo_rollouts                         = true
  # enable_aws_node_termination_handler          = true
  enable_aws_load_balancer_controller          = true
  # amazon_eks_aws_ebs_csi_driver_config         = true
  # enable_secrets_store_csi_driver_provider_aws = true
  # enable_tetrate_istio                         = var.enable_tetrate_istio
  # enable_aws_for_fluentbit                     = true

  tags = local.tags

  depends_on = [
    module.eks_blueprints
  ]

}
