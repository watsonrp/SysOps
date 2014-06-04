#!/bin/bash
  #Get instanceID
  IP=$(curl http://169.254.169.254/latest/meta-data/instance-id -s)
  #Check if sysstat was install
  /usr/bin/which sar
   if [ "$?" != "0" ];then
     echo "Sar Could be found?"
     exit 3
   fi   
  cswch=`sar 1 5 -w | grep Average | awk '{ print $3 }'`
  /usr/bin/aws cloudwatch put-metric-data --metric-name ContextSwitchesPerSecAvg --namespace "System/Linux" --statistic-value Sum=0,Minimum=0,Maximum=${cswch},SampleCount=5 --dimensions "InstanceId=${IP}" --region eu-west-1


    if [ "$?" != "0" ];then

     echo "Not Cool, AWS Command failed, Path?IAM Role? do not be lazy just run it interactivly and capture the error"
     #DEbug here
     echo $IP
     echo $cswch
     exit 3

    fi
exit 0
