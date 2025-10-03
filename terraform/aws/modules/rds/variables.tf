######################
# Required Variables #
######################

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance (AWS Academy supports: nano, micro, small, medium)"
  type        = string
}

variable "allocated_storage" {
  description = "The amount of allocated storage in gibibytes (max 100GB for AWS Academy)"
  type        = number
}

variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of VPC subnet IDs to place the RDS instance"
  type        = list(string)
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "stackfood"
}

variable "public_subnet_ids" {
  description = "A list of public VPC subnet IDs"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "rds_role_name" {
  description = "Name of the IAM role to use for enhanced monitoring (e.g., 'LabRole')"
  type        = string
}

######################
# Optional Variables #
######################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 5432
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance (max 100GB for AWS Academy)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type - AWS Academy only supports gp2 (general purpose SSD)"
  type        = string
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}
variable "publicly_accessible" {
  description = "Specifies whether the RDS instance is publicly accessible"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If not specified, the default RDS KMS key for the account will be used"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "The AZ for the RDS instance. Only used when multi_az is false"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "03:00-06:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = true
}

variable "allowed_security_groups" {
  description = "List of security group IDs to allow access to the RDS instance"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks which are allowed to access the RDS instance"
  type        = list(string)
  default     = []
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. If not specified, a name will be generated"
  type        = string
  default     = null
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate. If not specified, a name will be generated"
  type        = string
  default     = null
}

variable "create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  type        = bool
  default     = true
}

variable "family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "postgres16"
}

variable "parameters" {
  description = "A list of DB parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "option_group_name" {
  description = "Name of the DB option group to associate. If not specified, a name will be generated"
  type        = string
  default     = null
}

variable "create_db_option_group" {
  description = "Whether to create a database option group"
  type        = bool
  default     = false # Not needed for PostgreSQL
}

variable "major_engine_version" {
  description = "The major version of the engine to use for the option group"
  type        = string
}

variable "options" {
  description = "A list of options to apply"
  type = list(object({
    option_name = string
    option_settings = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

variable "db_username" {
  description = "The database username"
  type        = string
  default     = "stackfood"
}

variable "db_password" {
  description = "The database password (must be at least 8 characters). Only used if manage_master_user_password is false."
  type        = string
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager (RECOMMENDED for production)"
  type        = bool
  default     = true
}
