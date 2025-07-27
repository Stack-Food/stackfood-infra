variable "project_name" {
  type    = string
  default = "leo-teste-terraform"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "tags" {
  default = {
    Name = "leo-teste-terraform"
  }
}

variable "labRole" {
  default = "arn:aws:iam::651189048321:role/LabRole"
}

variable "principalArn" {
  default = "arn:aws:iam::651189048321:role/voclabs"
}

variable "policyArn" {
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

variable "accessConfig" {
  default = "API_AND_CONFIG_MAP"
}