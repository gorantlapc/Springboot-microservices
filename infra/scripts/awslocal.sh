#!/bin/bash

# Ensure awslocal is installed and LocalStack is running before executing this script.

export AWS_REGION='us-east-1'
export AWS_ACCESS_KEY_ID='test'
export AWS_SECRET_ACCESS_KEY='test'

# Create SNS topic and SQS queue in LocalStack
awslocal sns create-topic --name order-topic

# Get the SNS topic ARN
TOPIC_ARN=$(awslocal sns list-topics --query 'Topics[?contains(TopicArn, `order-topic`)].TopicArn' --output text)

# Create SQS
awslocal sqs create-queue --queue-name notification-queue

# Get the SQS queue ARN
QUEUE_ARN=$(awslocal sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/notification-queue \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text)

# Subscribe SQS queue to SNS topic
awslocal sns subscribe \
    --topic-arn ${TOPIC_ARN} \
    --protocol sqs \
    --notification-endpoint ${QUEUE_ARN}
# Get the subscription ARN
SUBSCRIPTION_ARN=$(awslocal sns list-subscriptions-by-topic --topic-arn ${TOPIC_ARN} --query 'Subscriptions[0].SubscriptionArn' --output text)

# Enable raw message delivery for the subscription
awslocal sns set-subscription-attributes \
   --subscription-arn ${SUBSCRIPTION_ARN} \
   --attribute-name RawMessageDelivery --attribute-value true