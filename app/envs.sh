#!/bin/bash

aws configure set region eu-west-1
SNS_TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn, 'ecs-sns-sqs-processor')].TopicArn" --output text)
sed -i "s/SNS_TOPIC_HERE/$SNS_TOPIC_ARN/g" ./app/app.py