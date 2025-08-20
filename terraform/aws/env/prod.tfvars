aws_region  = "us-west-2"
environment = "prod"

tags = {
  Project     = "StackFood"
  Team        = "DevOps"
  CostCenter  = "IT"
}

######################
# VPC Configuration #
######################
vpc_name       = "stackfood-prod-vpc"
vpc_cidr_blocks = ["10.0.0.0/16"]

private_subnets = {
  "private1" = {
    availability_zone = "us-west-2a"
    cidr_block        = "10.0.1.0/24"
  },
  "private2" = {
    availability_zone = "us-west-2b"
    cidr_block        = "10.0.2.0/24"
  },
  "private3" = {
    availability_zone = "us-west-2c"
    cidr_block        = "10.0.3.0/24"
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
  },
  "public3" = {
    availability_zone = "us-west-2c"
    cidr_block        = "10.0.103.0/24"
  }
}

######################
# EKS Configuration #
######################
eks_cluster_name = "stackfood-prod-eks"
kubernetes_version = "1.28"
eks_endpoint_public_access = false

eks_node_groups = {
  "app" = {
    desired_size  = 3
    max_size      = 6
    min_size      = 2
    ami_type      = "AL2_x86_64"
    capacity_type = "ON_DEMAND"
    instance_types = ["t3.large"]
    disk_size     = 50
    labels = {
      "role" = "app"
    }
  },
  "db" = {
    desired_size  = 2
    max_size      = 4
    min_size      = 2
    ami_type      = "AL2_x86_64"
    capacity_type = "ON_DEMAND"
    instance_types = ["t3.large"]
    disk_size     = 100
    labels = {
      "role" = "db"
    }
  }
}

######################
# RDS Configuration #
######################
rds_instances = {
  "stackfood-prod-db" = {
    subnet_group_name = "stackfood-prod-db-subnet-group"
    security_group_names = ["stackfood-prod-db-sg"]
    allocated_storage = 50
    storage_encrypted = true
    db_instance_class = "db.t3.large"
    engine = "postgres"
    engine_version = "14.5"
    identifier = "stackfood-prod-postgres"
    publicly_accessible = false
    multi_az = true
    performance_insights_enabled = true
    enable_backup_tagging = true
    snapshot_identifier = true
    username = "postgres" # Use AWS Secrets Manager in production
    port = 5432
    password = "ChangeMe123!" # Use AWS Secrets Manager in production
    backup_window = "03:00-06:00"
    maintenance_window = "Mon:00:00-Mon:03:00"
    deletion_protection = false
  }
}

######################
# Lambda Configuration #
######################
lambda_functions = [
  {
    name = "stackfood-prod-api"
    description = "API for StackFood production application"
    runtime = "nodejs18.x"
    handler = "index.handler"
    filename = "../lambdas/api.zip" # This should point to your lambda code
    source_code_hash = "" # Will be computed from the file
    memory_size = 512
    timeout = 30
    vpc_access = true
    environment_variables = {
      DB_HOST = "stackfood-prod-postgres.internal"
      DB_PORT = "5432"
      DB_NAME = "stackfooddb"
      LOG_LEVEL = "info"
      NODE_ENV = "production"
    }
  },
  {
    name = "stackfood-prod-worker"
    description = "Worker for StackFood production application"
    runtime = "nodejs18.x"
    handler = "worker.handler"
    filename = "../lambdas/worker.zip" # This should point to your lambda code
    source_code_hash = "" # Will be computed from the file
    memory_size = 1024
    timeout = 60
    vpc_access = true
    environment_variables = {
      DB_HOST = "stackfood-prod-postgres.internal"
      DB_PORT = "5432"
      DB_NAME = "stackfooddb"
      LOG_LEVEL = "info"
      NODE_ENV = "production"
      WORKER_CONCURRENCY = "10"
    }
  }
]