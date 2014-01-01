Just few scripts that will make you life easier ...
###################################################
30/12/2013 - tagBased.sh 
Version 0.1 - Initial
Goal - Stop or Terminate EC2 resources based on key:value Tag Pair , currently only support instance as resource type
PreReq:
  1. AWS Python CLI tools
  2. Access / Secert Key with IAM Policy that at mimimum needs permissions to: Describe/Stop/Terminate Instanceas/Tags and optionally send SNS message to topic
Usage: Just execute the script with no arguments to list the usage and options 
