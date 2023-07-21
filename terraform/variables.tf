variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_tetrate_istio" {
  description = "Enable istion deployment"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "Region name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC cidr"
  type        = string
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
}

# variable "node_security_group_additional_rules" {
#   type = map(
#     object(
#       {
#         description                   = string
#         protocol                      = string 
#         from_port                     = number 
#         to_port                       = number 
#         type                          = string 
#         source_cluster_security_group = optional(bool)
#         self                          = optional(bool)
#         cidr_blocks                   = optional(list(string))
#       }
#     )
#   )
# }

variable "argocd_workloads" {
  description = "Argocd workloads map"
  type = map(object({
    path               = string
    repo_url           = string
    add_on_application = bool
  }))
}

variable "install_calico" {
  description = "Enable calico deployment"
  type        = bool
  default     = true
}