# Run terraform 
1. Edit example.tfvars file.
2. terraform apply -var-file ./example.tfvars 

# Ingress controller issue remediation
Ingress controller has got an issue due to which it can't provision balancers.
In order to remediate this issue, please drop followin lines from IAM role assigned to controller's user

"Condition": {
    "Null": {
        "aws:ResourceTag/ingress.k8s.aws/cluster": "false"
    }
},

Issue link: https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/issues/200