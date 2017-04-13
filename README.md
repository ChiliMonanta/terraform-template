# Terraform template

A terraform template for a vpc with app server and load balancer.
Access logs are sent to s3 every 60 minutes.
Execute global before app specific infrastructure

## Prerequisites

1. Setup yor aws profile [docs](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration)

        aws configure --profile user2

2. Create key pair  [docs](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)

## Actions:

Parameters:

- env: prod, stage, dev, global


Plan

    make env=dev plan

Apply

    make env=dev apply

Destroy

    make env=dev destroy

Clean

    make clean


Note:
Problem with bootstrap (user_data), see /var/log/cloud-init-output.log