Summary
=======

Simple program which loops the describe ec2 API seeking for key:value pair and act upon: stop/terminate in addition will send SNS Messages to pre-defined topic

Name
====
tagBased.sh

Goal
====
Stop or Terminate EC2 resources based on key:value Tag Pair , currently only support instance as resource type , future will also suppot EBS volumes

PreReq
======

  * AWS Python CLI tools
  * Access / Secert Key with IAM Policy that at mimimum needs permissions to: Describe/Stop/Terminate Instanceas/Tags and optionally send SNS message to topic

Usage
=====

Just execute the script with no arguments to list the usage and options 
