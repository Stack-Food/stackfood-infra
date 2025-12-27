######################
# Data Sources #
######################

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account
data "aws_caller_identity" "current" {}
