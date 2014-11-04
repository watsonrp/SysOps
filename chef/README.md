Summary
=======
bootstrap your instance automatically with chef-solo, the purpose is to demonstrate to students how *relatively* easy it is to use automation tools such as chef-solo to automate deployments on AWS.
By all means this mini framework does not "compete" with a fully blown chef-server / OpsWorks frameworks, its sole purpose is to provide a simple yet powerful first step into automating instance deployments


Components
==========

* Admin Instance - The instance that will orchestrate the instance deployment
* Generic EC2 Instance - Simply the instance that will be launched as part of the process
* Chef-solo - The chef-client that will be executed on every Generic EC2 Instance to deploy the cookbooks / recipes 
* State Server - Simple S3 Bucket with a pre defined hierarchy, used to manage the state/configuration of the deployed EC2 Instances outside the instance
* Instance Role/Instance Profile - Used to allow the Generic EC2 instance to make Authenticated API calls to the S3 bucket in order to download/sync chef-solo configurations
* Cookbooks - Contains the Recipes that will be executed on the bootstrapped instance A collection of Recipes may be referred as cookbooks


Per Component Requirement
=========================
*Admin Instance*

* Ubuntu (Might also work with Linux AMI did not test it)
* AWS python CLI Tools version 1.2.9 (latest to the time this README is written)
* AWS Python CLI Access Key/Secret Key Configuration at ~/.aws/config , with policy permission that is able (At min) to: Start new instances , Describe new instances 
  S3 Put-Objects/Get-Objects to the S3 Bucket that will hold the chef-solo configurations
* Public Access - Since we make calls to S3 we need Internet Access , NAT , Or Public IP ... Your Choice :-)

*Generic EC2 Instance*

* Supported AMI: Ubuntu 14.04 , was not tested on other Linux Platform but can surely fitted into ones ...
* Instance Profile-->IAM Role - an IAM Role that allows the Generic EC2 Instance to do Authenticated API calls to the S3 Bucket in order to retrieve Configurations that
  Were Created by the Admin Instance (See Installation Instruction on how-to create) , the Role must be created manually and be assigned to an Instance-Profile ,
  The Instance Profile Arn will be used as an Argument on the Bootstrapping Process 

*Chef-solo*

* No Special Requirements, We use OpsCode's Generic Platform Independed bootstrap script

*S3 Bucket*

* Generic S3 Bucket, Can reside in any region
* Pre-Defined Hierarchy (See Installation Instructions) 


Supported Platforms
===================

Currently only ubuntu is supported, but can easily add additional platforms

General Flow
============

Bootstrap new instance using newInstance.sh --> Based on arguments chef-solo configs are created per instance and pushed to s3 ---> User Data executes bootstrap.sh --> bootstrap.sh create the chef-solo environment and downloads the configs that were generated --> bootstrap.sh calls chef-solo install.sh --> install.sh detects OS and Distro and installs chef-solo client --> eventually bootstrap.sh execute chef-solo and create a cronjob 

Programs
========

newInstance.sh - This is a wrapper around the AWS CLI tool, This scripts will start a new AWS Instance it will take a chef role as an argument and will translate it to a chef run list for the instance by creating custom configuration then upload them to S3

bootstrap.sh - This is the code that runs on the instance via user-data which will built all the chef-solo environment Including downloading the 
Generated Configurations and eventually execute chef-solo for the deployment process

solocron.sh - A cron job script that will be executed every 20 minutes and check if there are configuration updates (new cookbooks/new roles...) and download them to the 
Instance , then execute chef-solo

Installation Instructions
=========================


This process is not short :-) , but most of the time should only done once and be tweaked as needed

*step 1 - S3*

- Create an S3 Bucket with your favourite name, create the below structure and copy the files from the repo root and the s3 folder  to the appropriate s3 prefix below:

```MyBucket---
          |--cookbook
                    |--solo-all.tar.gz
                    |--solo-all.tar.gz.md5   (Just create an md5 of the solo-all.tar.gz file and echo it into this file)
          |--others
                  |--install.sh
                  |--bootstrap.sh
                  |--solocron.sh
          |--solorb
          |--nodejson
          |--roles
                 |--roles.tar.gz 
                 |--roles.tar.gz.md5 (Just create an md5 of the roles.tar.gz file and echo it into this file)
```
- All bucket Objects needs to be private, except the others "Folder" , Grant Public Access to the others folder and its content , so when you upload new versions
  Of the scripts make sure to make the, publicly available

- Download the chef client install script:  https://www.opscode.com/chef/install.sh and copy it to others/install , make the script public accesible

*Step 2 - IAM*

- Create an IAM role and attach a policy that allows s3 read access to the objects in MyBucket (see s3-generic-instance-role.policy) , We will assosiacte
  This role with an Instance Profile , The Bootstrapped instance will be attached with the instance profile
- Create an IAM Instance Profile and add the above created Role to the instance profile, Records its ARN, you will need it as an Argument for the newInstance.sh program

  Example Creating the Instance Profile:

  ```aws iam create-instance-profile --instance-profile-name s3-myBucket-access```

  Example Assosiating the Role with the Instance Profile:

  ```aws iam add-role-to-instance-profile --instance-profile-name s3-myBucket-access --role-name myBucket-iam-role```

- Needless to say that your admin instance needs read/write access to this bucket as well, so if you need to create a dedicated role and a policy for it
  now its the time to do it

*Step 3 - Admin Instance*

- Launch an ubuntu EC2 AMI (Generic one), I would choose m1.small for this purpose, MAKE SURE To ASSOCIATE the instance with the appropriated IAM ROLE to enable S3 Read/Write 
  Access to the S3 MyBucket
- Install aws cli :  apt-get update && apt-get install -y python-pip && pip install awscli
- Configure default region (where the s3 bucket lives) , aws configure 
- Create: /srv/bootstrap  , /srv/bootstrap/nodejson , /srv/bootstrap/solorb
- Copy newInstance.sh,user-data.sh,solo.rb,base.json,web.json to /srv/bootstrap , Make sure that all scripts are +x :-)
- Edit the newInstance.sh and replace the default bucket name with your bucket name
- Edit the user-data.sh and replace the default bucket name with your bucket name
- Download bootstrap.sh and replace the default bucket name with your bucket name as well as the REGION that your s3 bucket lives in 
- RE: Upload boostrap.sh to the s3 bucket into others/bootstrap.sh , make the file PUBLIC
- Download solocron.sh and replace the default bucket name with your bucket name as well as the REGION that your s3 bucket lives in
- RE: Upload boostrap.sh to the s3 bucket into others/solocron.sh

*Step 4 - Launch An Instance*

****Important: I assume that you launch the instance into a pre-existing VPC , into a valid existing PUBLIC SUBNET that automatically assigned public IP
               to the newly launched instances****

- Change dir to /srv/bootstrap
- Execute the newInstance.sh , provide all the needed arguments , for the chef role currently only base and web are supported try them both !

Usage:

usage: ./newInstance.sh -a AMI-ID -s securityGroupIDs -k KeyPairName -i InstanceSize -n VPCsubnetID -m IAM-Instance-Profile(Arn=value) -r ChefRole

Currently ChefRole can be "base" or "web"

Example:

 /newInstance.sh -a ami-a53264cc -s xxxxxxxx -k xxxxxxxx -i t1.micro -n subnet-xxxxxxxx -m Arn=arn:aws:iam::xxxxxxxxxxxxxxxx:instance-profile/s3-chef-solo -r web

- Login to the instance after a few minutes the chef-solo web role should have installed ntpd and apache2 automatically!

Author
======

Kobi Biton:  kobibito@amazon.lu


