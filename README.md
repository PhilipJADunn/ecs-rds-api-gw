# Walkthrough

First I'll walkthrough the setup and then at the end I will list improvements.

Reading through the initial scenario I opted for ALB <> ECS <> SNS/SQS <> LAMBDA <> AURORA POSTGRES RDS

I did consider using an API GW to front traffic: APIGW <> SNS/SQS <> ECS <> DB

However I kept finding myself in this scenario to believe a Lambda function would be sufficient and thus ECS would not have been involved despite the scenario mentioning it explicitly.

I believe what I opted for is a good event driven architecture that can handle increases in load, while distributing traffic across AZs while resources are not tightly coupled. We can use the SNS to fanout to other services in the future, setting up a cross account SNS/SQS from here would not be an issue and would allow other teams within the business access quickly.

This shows how combining the various building blocks AWS provides we can design a scalable, reliable, event-driven system that isn't going to break the bank.

## Containerisation

I decided to go for a slim image to keep build and deployment time as low as possible, I went for a single stage build as we don't require the use of apt-get to install dependencies, these are stored in requirements.txt. For a production system with more steps in our dockerfile I would opt to cache as many layers as I could depending on how often changes were made in those layers.

I have created a new user so we are not using root user privileges. This image was tested locally first. This may be a small thing but I've found more junior engineers may well sit and wait for a task to fail in AWS.

## Terraform

I Will outline how I have built Terraform here and below with each module specifically, I opted for modules for reusability and maintainability. You'll note that we don't have a parent/child module setup, while I do like this setup as it makes using outputs and data easier there are also drawbacks, such as a complexity, if you aren't careful then these can get complex quite quickly where you can end up creating a dependency that may cause some issues down the line. 

terraform_remote_state can be very useful for pulling in the information required.

So we have separate modules called in separately, this creates smaller more manageable state files (not that you should ever have to manage a state file, certainly avoid the temptation to manually change one). A smaller state file will result in quicker deployments per group of resources. This is quite a common way to build resources if using Terraform Cloud as a backend.

## Network

I opted to use an existing module from the registry that would deploy a VPC, 3 public and 3 private subnets, route tables and also an IGW, NACLs and flow logs.
I made the decision at this point to not deploy a NAT GW to save on cost as it would not be required.

## ECS

I opted to build this module myself, I noted a lot of existing modules had networking resources, such as a VPC and subnets so thought best to do this myself, I decided to deploy into a public subnet and fronted requests with an ALB. The reasoning was additionally configuration being required in private subnets via VPC Endpoints. For public subnets I assigned a public IP to tasks otherwise we get failures to ECR.

If we need to log into a container we can do via ECS Exec. One of the reasons for choosing fargate over EC2 here was because it includes all the requirements to use ECS Exec, just need to make sure running Platform Version 1.4 - https://aws.amazon.com/blogs/containers/aws-fargate-platform-versions-primer/

For the code here I dig some digging into the AWS SDK for SNS - https://docs.aws.amazon.com/code-library/latest/ug/python_3_sns_code_examples.html

I've also called in an ASG module that will scale on CPU.

## Events

Here we have our serverless resources. I opted to group all of these together under one module mainly due to security between Lambda Environment variables and the secrets required to connect to the database (more about improvements there later on). Calling in username/password and host id in plaintext, with the details of such sat in a statefile was something I wished to avoid.

I enjoyed building these resources this way, I have done a lot more serverless using CloudFormation than Terraform over the years when it comes to SNS/SQS and Lambda. Resolving secrets is something CloudFormation does easier than TF in this regard as it happens.

For the function code I used this AWS article - https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-lambda-tutorial.html

For the DB itself I went for a serverless postgres build, for this I felt it would suit the workload while being able to scale as required, getting instance sizing correct first time can be a tricky thing to do if you are simply predicting traffic load with no data to back it up. Sizing too small can make for some very unhappy people at a peak time, certainly if it's a Friday. Sizing too large is going to make the billpayer very unhappy aswell.

Data here will be encrypted at rest.

## CI/CD

My CI/CD experience is mainly in AWS' suite of services but I have recently been enjoying using GitHub Actions as something a little different. cicd.yaml has a role assigned to it with OIDC provider assigned to GitHub, as does terraform.yml. You can create a user and call in their access key via secrets.

I have a script here in cicd.yaml to grab an SNS Topic ARN and insert it into app.py, from here, we then login to ECR and download our task definition and then build,tag and push our docker image.

Finally we update our task def and deploy it.

Terraform is deployed when there are changes to any file within iac/terraform, we have a dependency here for the DB to speak to the DB via psycopg2 so we package this up here. From there we run checks on each module to see if there are any changes and deploys them.

## Improvements for a production environment

To make this a production ready multi environment service there are some improvements to be made. 

### Terraform
Naming conventions to include the environment and service, these are usually saved as variables, e.g "stag-product-function". Just a note here as I am aware that the SNS and SQS names may seem slightly confusing because of this, I tend to name SQS resources as 'upstream service-queuename-downstream service' I find this is a good naming convention and allows people who haven't worked on a service before to understand the workflow quicker.

We should also parameter our S3 bucket for the backend, however, using the data source to pull in account id results in an error for the terraform backend block, so it may be worth just using a variable here.

### ECS

We would deploy into private subnets and use VPCEs. Instead of exposing the ALB URL we would deploy a domain name via Route 53 and an ACM cert to secure the traffic over 443 to the ALB. We would also configure container logging.

We would also deploy Cognito if we didn't want to authenticate within ECS. Currently the ALB is locked down to my IP but authenticating 3rd parties who may use this in the future via IP is not considered best practice.

### CI/CD

We could build and tag images with the commit SHA instead of latest and we could also use env vars for the region and IAM Role.

A blue/green deployment to send 10% of traffic for 10 minutes to a new task before switching over could also be implemented.

### Logging

While we have a couple of CW alarms for our ASG, we would want more alarms so we can monitor our services, for the ALB we would likely want to see 5XX and 4XX errors. HealthyHostCount being another. For ECS we have CPUUtilization but we may want to include MemoryUtilization and RunningTaskCount. SQS we want an alarm setting up if the DLQ is filling with messages. For the Lambda we can set a metric if we get x% of errors within a certain time period. For Aurora Serverless Postgres DB we should have CPUUtilization and ACUUtilization.

Of course there are others aswell but these are the first that spring to mind. We should implement our service with Grafana and Dynatrace aswell for example, so we can gain some better insights over time. I tend to keep some monitoring dashboards open during deployment, this can help me quickly see if we have an issue and roll back.

We would also set these alarms up with alerts, we can use SNS to send to slack to notify us during working hours, and Pagerduty/Incident.io.

### Disclaimer

I have not fully tested this as of when you have received the zip file, it does however deploy into ECS and terraform deploys locally. I look forward to discussing this with you on Friday.
