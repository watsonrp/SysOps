Summary
=======
bootstrap you instance automatically with chef-solo, the purpose is to demonstrate to students how *relatively* easy it is to use automation tools such as chef-solo to automate deployments on AWS.
By all means this mini framework does not "compete" with a fully blown chef-servr / OpsWorks frameworks, its sole purpose is to provide a simple yet powerful first step into automating instance deployments

Requirments:

 * EC2 Instance with permissions to read/write to/from an S3 bucket , describe instances ,  AWS CLI Tools (Python Version) might refer to it as your admin instance all script will be executed from it.
 * An S3 bucket with a pre-defined folder tree (will be provided at zip file) , also recommending that the admin instance will be attached with an IAM role that grants r/w access to this S3 Bucket
 * IAM Role which a policy attached to it that permits read access to the above S3 Bucket, when you will bootstrap the instance you will need to provide that IAM Role as an instance profile (See example below)

Might be used an a short Interactive Demo, Just to show how powerful and simple SNS Can be used in certain automation processes!, or one can ref student to this github repo for to download and use the code.

Supported Platforms
===================

Currently only ubuntu is supported, but can easily add additional platforms

General Flow
============

Bootstrap new instance using newInstance.sh --> Based on arguments chef-solo configs are created per instance and pushed to s3 ---> User Data executes bootstrap.sh --> bootstrap.sh create the chef-solo environment and downloads the configs that were generated --> bootstrap.sh calls chef-solo install.sh --> install.sh detects OS and Distro and installs chef-solo client --> eventaully bootstrap.sh execute chef-solo and create a cronjob 

Components
==========

newInstance.sh - This is a wrapper around the AWS CLI tool, This scripts will start a new AWS Instance it will take a chef role as an argument and will translate it to a chef run list for the instance by creating a custom config
                 And upload it

bootstrap.sh - this is the code that runs on the instance via user-data which will built all the chef-solo environment and eventually execute chef-solo

solocron.sh - A cron job script that will be executed every 20 minutes and download changes then execute chef-solo

s3 Bucket - the S3 Bucket is used to keep the chef cookbooks / Roles / solo.rb (main chef-solo config file) , this way the state is managed outside the instance for better managability 

solo.rb - Template file for the main chef solo configuration file it will be stored on the instance at: /etc/chef

node.json - Template file for the chef node json file, this actually tells chef solo which recipes / roles to execute

base.json/web.json - Template chef-solo role files

Logging
=======


