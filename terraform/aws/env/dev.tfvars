aws_region  = "us-west-2"
environment = "dev"

tags = {
  Project    = "StackFood"
  Team       = "DevOps"
  CostCenter = "IT"
}

######################
# VPC Configuration #
######################
vpc_name        = "stackfood-dev-vpc"
vpc_cidr_blocks = ["10.0.0.0/16"]

private_subnets = {
  "private1" = {
    availability_zone = "us-west-2a"
    cidr_block        = "10.0.1.0/24"
  },
  "private2" = {
    availability_zone = "us-west-2b"
    cidr_block        = "10.0.2.0/24"
  }
}

public_subnets = {
  "public1" = {
    availability_zone = "us-west-2a"
    cidr_block        = "10.0.101.0/24"
  },
  "public2" = {
    availability_zone = "us-west-2b"
    cidr_block        = "10.0.102.0/24"
  }
}

######################
# EKS Configuration #
######################
eks_cluster_name           = "stackfood-dev-eks"
kubernetes_version         = "1.28"
eks_endpoint_public_access = true

eks_node_groups = {
  "app" = {
    desired_size   = 2
    max_size       = 3
    min_size       = 1
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.medium"]
    disk_size      = 20
    labels = {
      "role" = "app"
    }
  },
  "db" = {
    desired_size   = 1
    max_size       = 2
    min_size       = 1
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.medium"]
    disk_size      = 20
    labels = {
      "role" = "db"
    }
  }
}

######################
# RDS Configuration #
######################
db_identifier              = "stackfood-dev-postgres"
db_name                    = "stackfooddb"
db_username                = "postgres"
db_password                = "ChangeMe123!"
db_port                    = 5432
db_engine_version          = "14.5"
db_instance_class          = "db.t3.small"
db_allocated_storage       = 20
db_max_allocated_storage   = 100
db_backup_retention_period = 7
db_backup_window           = "03:00-06:00"
db_maintenance_window      = "Mon:00:00-Mon:03:00"
db_multi_az                = false
db_deletion_protection     = false

######################
# IAM Configuration #
######################
lambda_role_name      = "LabRole"
eks_cluster_role_name = "LabEksClusterRole"
eks_node_role_name    = "LabEksNodeRole"

######################
# Lambda Configuration #
######################
lambda_functions = [
  {
    name             = "stackfood-dev-api"
    description      = "API for StackFood development application"
    runtime          = "nodejs18.x"
    handler          = "index.handler"
    filename         = "../lambdas/api.zip"
    source_code_hash = ""
    memory_size      = 128
    timeout          = 30
    vpc_access       = true
    environment_variables = {
      DB_HOST   = "stackfood-dev-postgres.internal"
      DB_PORT   = "5432"
      DB_NAME   = "stackfooddb"
      LOG_LEVEL = "debug"
      NODE_ENV  = "development"
    }
  },
  {
    name             = "stackfood-dev-worker"
    description      = "Worker for StackFood development application"
    runtime          = "nodejs18.x"
    handler          = "worker.handler"
    filename         = "../lambdas/worker.zip"
    source_code_hash = ""
    memory_size      = 256
    timeout          = 60
    vpc_access       = true
    environment_variables = {
      DB_HOST            = "stackfood-dev-postgres.internal"
      DB_PORT            = "5432"
      DB_NAME            = "stackfooddb"
      LOG_LEVEL          = "debug"
      NODE_ENV           = "development"
      WORKER_CONCURRENCY = "5"
    }
  }
]
