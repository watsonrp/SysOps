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
* Latest AWS python CLI Tools
* AWS Python CLI Access Key/Secret Key Configuration at ~/.aws/config , with policy permission that is able (At min) to: Start new instances , Describe new instances, 
  Pass IAM Role, S3 Put-Objects/Get-Objects to the S3 Bucket that will hold the chef-solo configurations, IAM Role is always better and more secured!
* Public Access - Since we make calls to S3 we need Internet Access , NAT , Or Public IP ... Your Choice :-)

*Generic EC2 Instance*

* Supported AMI: Ubuntu 14.04 , was not tested on other Linux Platform but can surely fitted into ones ...
* Instance Profile-->IAM Role - An IAM Role that allows the Generic EC2 Instance to do Authenticated API calls to the S3 Bucket in order to retrieve Configurations that
  Were Created by the Admin Instance (See Installation Instruction on how-to create) , the Role must be created manually and be assigned to an Instance-Profile ,
  The Instance Profile Arn (Amazon Resource Name) will be used as an Argument for the Bootstrapping Process 

*Chef-solo*

* No Special Requirements, We use OpsCode's Generic Platform bootstrap script

*S3 Bucket*

* Generic S3 Bucket, Can reside in any region
* Pre-Defined Hierarchy (See Installation Instructions) 


Supported Platforms
===================

Currently only Ubuntu is supported, but can easily add additional platforms

General Flow
============

Bootstrap new instance using newInstance.sh --> Based on arguments chef-solo configs are created per instance and pushed to s3 ---> User Data executes bootstrap.sh --> bootstrap.sh create the chef-solo environment and downloads the configs that were generated --> bootstrap.sh calls chef-solo install.sh --> install.sh detects OS and Distro and installs chef-solo client --> eventually bootstrap.sh execute chef-solo and create a cronjob 

Programs
========

newInstance.sh - This is a wrapper around the AWS CLI tool, This scripts will start the new AWS Instance, It will take a chef role as an argument and will translate it to a chef run list for the instance by creating custom configurations then, upload them to S3

bootstrap.sh - This is the code that runs on the instance via user-data which will built all the chef-solo environment Including downloading the 
Generated Configurations and eventually execute chef-solo for the deployment process

solocron.sh - A cron job script that will be executed every 20 minutes and check if there are configuration updates (new cookbooks/new roles...) and download them to the Instance , Then execute chef-solo

Installation Instructions
=========================

This process is not short :-) , but most of the time should only done once and tweaked as needed

*Step 1 - IAM*
--------------

IAM Role - Bootstrapped Instance

- Create an IAM role and attach a policy that allows s3 read access to the objects in MyBucket (see s3-generic-instance-role.policy) , We will associate
  This role with an Instance Profile , The Bootstrapped instance will be attached with the instance profile
- Create an IAM Instance Profile and add the above created Role to the instance profile, Records its ARN, you will need it as an Argument for the newInstance.sh program

  Example Creating the Instance Profile:

  ```aws iam create-instance-profile --instance-profile-name s3-myBucket-access```

  Example Associating the Role with the Instance Profile:

  ```aws iam add-role-to-instance-profile --instance-profile-name s3-myBucket-access --role-name myBucket-iam-role```
  
IAM Role - Admin Instance

- Needless to say that your admin instance needs read/write access to this bucket and permission to launch new instances (see Per Component Requirement)

*Step 2 - Admin Instance*
-------------------------

- Launch an ubuntu EC2 AMI (Generic one), I would choose m3.medium for this purpose, MAKE SURE To ASSOCIATE the instance with the appropriated IAM ROLE
  That is if you decided to use IAM Role for the admin instance permissions
- SSH To the instance : Install aws cli :  apt-get update && apt-get install -y python-pip && pip install awscli
- Configure aws cli tools, type: aws configure , provide ak/sk(if used) and the region where the bucket lives
- Create: /srv/bootstrap
- From Github project root :  Download admin-instance.tar.gz to /srv/bootstrap , extract the file: tar xvfz admin-instance.tar.gz
- Edit the newInstance.sh and replace the default bucket name with your bucket name (Do not worry you will create the bucket on the next step)
- Edit user-data.sh and replace the default bucket name with your bucket name
- Edit bootstrap.sh and replace the default bucket name with your bucket name as well as the REGION that your s3 bucket lives in 
- Edit solocron.sh and replace the default bucket name with your bucket name as well as the REGION that your s3 bucket lives in


*step 3 - Create The Artifcats S3 Bucket*
-----------------------------------------

- Create an S3 Bucket with your favorite name, create the below structure and copy from the admin instance/github s3 folder to the appropriate paths:

***Important Notice the S3 Bucket Must be Created @ the SAME REGION that you configured above!

```MyBucket---
          |--cookbook
                    |--solo-all.tar.gz (To be taken as is from the github s3/ folder)
                    |--solo-all.tar.gz.md5 (To be taken as is from the github s3/ folder)   
          |--others
                  |--install.sh   (Download the latest from here: https://www.opscode.com/chef/install.sh)
                  |--bootstrap.sh (Upload from the admin instance *After Modifying the Bucket name & Region*
                  |--solocron.sh (Upload from the admin instance *After Modifying the Bucket name & Region*
          |--solorb  (Empty "Folder")
          |--nodejson (Emtpy "Folder")
          |--roles
                 |--roles.tar.gz (To be taken as is from the github s3/ folder)
                 |--roles.tar.gz.md5 (To be taken as is from the github s3/ folder)
```
- PERMISSIONS: All bucket Objects can be private, except the others "Folder" , Grant Public Access to all objects
 			   You could also use an IAM Resource Based Policy for this purpose


*Step 4 - Launch An Instance*
-----------------------------

****Important: I assume that you launch the instance into a pre-existing VPC , into a valid existing PUBLIC SUBNET that automatically assigned public IP
               to the newly launched instances****

- Change dir to /srv/bootstrap
- Execute the newInstance.sh , provide all the needed arguments , for the chef role currently only base and web are supported!

Usage:

usage: ./newInstance.sh -a AMI-ID -s securityGroupIDs -k KeyPairName -i InstanceSize -n VPCsubnetID -m IAM-Instance-Profile(Arn=value) -r ChefRole

Currently ChefRole can be "base" or "web"

Example:

Start an EC2 Instance and have chef deploy it as a webserver:

 /newInstance.sh -a ami-423c0a5f -s xxxxxxxx -k xxxxxxxx -i m3.medium -n subnet-xxxxxxxx -m Arn=arn:aws:iam::xxxxxxxxxxxxxxxx:instance-profile/s3-chef-solo -r web

- Login to the instance after a few minutes the chef-solo web role should have installed apache2 automatically!, browse to the ec2 instance public ip

Troubleshooting
===============

 The first step to troubleshoot is logs , I made sure that all the bootstrap process will be logged for any possible error:
 
 SSH login to the instance and examine the following logs in that order:
   
 - /var/log/cloud-init-output ---> Very important log , the user-data execute stdout will be logged here so if for some reason
   bootstrap.sh could not be downloaded from s3 the error will appear here
 - /var/log/bootstrap.log ---> If the bootstrap started this log will log errors or success 
 - /var/log/solorun.log ---> This logs means that chef-solo has executed , used to troubleshoot cookbook installation issues

Author
======

Kobi Biton:  kobibito@amazon.lu


