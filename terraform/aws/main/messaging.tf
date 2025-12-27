# ============================================
# StackFood - Event-Driven Messaging Infrastructure
# ============================================
# This file defines all SNS topics, SQS queues, and their subscriptions
# for event-driven communication between microservices.
#
# Event Flow:
# 1. Customers → CustomerEvents SNS Topic
# 2. Orders → OrderEvents SNS Topic → Payments Queue, Production Queue
# 3. Payments → PaymentEvents SNS Topic → Orders Queue
# 4. Production → ProductionEvents SNS Topic → Orders Queue
# ============================================

locals {
  # ============================================
  # SNS Topics Configuration
  # ============================================
  sns_topics = {
    # Customer Events Topic
    "stackfood-customer-events" = {
      display_name                = "StackFood Customer Events"
      fifo_topic                  = false
      content_based_deduplication = false
      tags = {
        Service     = "customers"
        MessageType = "events"
      }
      # SQS Subscriptions for Customer Events
      sqs_subscriptions = {}
    }

    # Order Events Topic
    "stackfood-order-events" = {
      display_name                = "StackFood Order Events"
      fifo_topic                  = false
      content_based_deduplication = false
      tags = {
        Service     = "orders"
        MessageType = "events"
      }
      # SQS Subscriptions for Order Events
      sqs_subscriptions = {
        # Payments Queue - receives order events
        "payments" = {
          queue_name           = "stackfood-payment-events-queue"
          raw_message_delivery = false
          filter_policy = {
            eventType = ["OrderCreated", "OrderCancelled"]
          }
        }
        # Production Queue - receives order events
        "production" = {
          queue_name           = "stackfood-production-events-queue"
          raw_message_delivery = false
          filter_policy = {
            eventType = ["OrderCreated", "OrderConfirmed"]
          }
        }
      }
    }

    # Payment Events Topic
    "stackfood-payment-events" = {
      display_name                = "StackFood Payment Events"
      fifo_topic                  = false
      content_based_deduplication = false
      tags = {
        Service     = "payments"
        MessageType = "events"
      }
      # SQS Subscriptions for Payment Events
      sqs_subscriptions = {
        # Orders Queue - receives payment status updates
        "orders-payment" = {
          queue_name           = "stackfood-order-payment-events-queue"
          raw_message_delivery = false
          filter_policy = {
            eventType = ["PaymentApproved", "PaymentFailed", "PaymentRefunded"]
          }
        }
      }
    }

    # Production Events Topic
    "stackfood-production-events" = {
      display_name                = "StackFood Production Events"
      fifo_topic                  = false
      content_based_deduplication = false
      tags = {
        Service     = "production"
        MessageType = "events"
      }
      # SQS Subscriptions for Production Events
      sqs_subscriptions = {
        # Orders Queue - receives production status updates
        "orders-production" = {
          queue_name           = "stackfood-order-production-events-queue"
          raw_message_delivery = false
          filter_policy = {
            eventType = ["ProductionStarted", "ProductionCompleted", "ProductionFailed"]
          }
        }
      }
    }
  }

  # ============================================
  # SQS Queues Configuration
  # ============================================
  sqs_queues = {
    # Payment Events Queue
    # Consumes: Order events from stackfood-order-events topic
    "stackfood-payment-events-queue" = {
      fifo_queue                        = false
      content_based_deduplication       = false
      delay_seconds                     = 0
      max_message_size                  = 262144 # 256 KB
      message_retention_seconds         = 1209600 # 14 days
      receive_wait_time_seconds         = 10 # Long polling
      visibility_timeout_seconds        = 300 # 5 minutes
      sqs_managed_sse_enabled           = true
      create_dlq                        = true
      max_receive_count                 = 3
      dlq_message_retention_seconds     = 1209600 # 14 days
      create_default_policy             = true
      allowed_sns_topic_names           = ["stackfood-order-events"]
      tags = {
        Service     = "payments"
        MessageType = "queue"
        SourceTopic = "stackfood-order-events"
      }
    }

    # Production Events Queue
    # Consumes: Order events from stackfood-order-events topic
    "stackfood-production-events-queue" = {
      fifo_queue                        = false
      content_based_deduplication       = false
      delay_seconds                     = 0
      max_message_size                  = 262144
      message_retention_seconds         = 1209600
      receive_wait_time_seconds         = 10
      visibility_timeout_seconds        = 300
      sqs_managed_sse_enabled           = true
      create_dlq                        = true
      max_receive_count                 = 3
      dlq_message_retention_seconds     = 1209600
      create_default_policy             = true
      allowed_sns_topic_names           = ["stackfood-order-events"]
      tags = {
        Service     = "production"
        MessageType = "queue"
        SourceTopic = "stackfood-order-events"
      }
    }

    # Order Payment Events Queue
    # Consumes: Payment events from stackfood-payment-events topic
    "stackfood-order-payment-events-queue" = {
      fifo_queue                        = false
      content_based_deduplication       = false
      delay_seconds                     = 0
      max_message_size                  = 262144
      message_retention_seconds         = 1209600
      receive_wait_time_seconds         = 10
      visibility_timeout_seconds        = 300
      sqs_managed_sse_enabled           = true
      create_dlq                        = true
      max_receive_count                 = 3
      dlq_message_retention_seconds     = 1209600
      create_default_policy             = true
      allowed_sns_topic_names           = ["stackfood-payment-events"]
      tags = {
        Service     = "orders"
        MessageType = "queue"
        SourceTopic = "stackfood-payment-events"
      }
    }

    # Order Production Events Queue
    # Consumes: Production events from stackfood-production-events topic
    "stackfood-order-production-events-queue" = {
      fifo_queue                        = false
      content_based_deduplication       = false
      delay_seconds                     = 0
      max_message_size                  = 262144
      message_retention_seconds         = 1209600
      receive_wait_time_seconds         = 10
      visibility_timeout_seconds        = 300
      sqs_managed_sse_enabled           = true
      create_dlq                        = true
      max_receive_count                 = 3
      dlq_message_retention_seconds     = 1209600
      create_default_policy             = true
      allowed_sns_topic_names           = ["stackfood-production-events"]
      tags = {
        Service     = "orders"
        MessageType = "queue"
        SourceTopic = "stackfood-production-events"
      }
    }
  }
}

# ============================================
# Module Instantiation - SQS Queues
# ============================================
# Note: This overrides the existing module "sqs" in main.tf
# The module declaration will use local.sqs_queues instead of var.sqs_queues

# ============================================
# Module Instantiation - SNS Topics
# ============================================
# Note: This overrides the existing module "sns" in main.tf
# The module declaration will use local.sns_topics instead of var.sns_topics
