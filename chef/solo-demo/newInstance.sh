#!/bin/bash
#
#Kobi Biton: kobibito@amazon.lu
#Version 1.0
#######################IMPORTANT NOTES
#md5sum print $4 awk was changed to support my md5 mac osx output , NEED to change ubuntu style! , which is print $1!
#######################
# Yet another script to start aws instance but this time integrates into chef-solo!
BUCKET="kiputch-solo"
##Functions
function error_exit()
{

    echo "Fatal Error: $1 Will exit now"
    exit 1
}

function ok_cont()
{
    echo "$1"

}
cleanup()
{
rm -f /tmp/Newinstance
rm -f /tmp/stderr
}
usage()
{
cat << EOF

usage: $0 -a AMI-ID -s securityGroupIDs -k KeyPairName -i InstanceSize -n VPCsubnetID -m IAM-Instance-Profile(Arn=value) -r ChefRole 

Currently ChefRole can be "base" or "web"

EOF
exit 1
}
while getopts “a:s:k:i:n::m:r:?” OPTION
do
     case $OPTION in
         a)
             AMIID=$OPTARG
             ;;
         s)
             SECGRPID=$OPTARG
             ;;
         k)
             KPNAME=$OPTARG
             ;;
         i)  
             INSTS=$OPTARG
             ;;  
         n)
             SBID=$OPTARG
             ;;
         m)  IAM=$OPTARG
             ;;
         r)  
             CHEFR=$OPTARG
             ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

if [[ -z $AMIID ]] || [[ -z $SECGRPID ]] || [[ -z $KPNAME ]] || [[ -z $INSTS ]] || [[ -z $SBID ]] || [[ -z $IAM ]] || [[ -z $CHEFR ]]
then
     usage
     exit 1
fi
md5up()
{
  md5sum $1 | awk 'BEGIN { FS=" " };{ print $1 }' > "$1.md5"
  for i in "${PIPESTATUS[@]}"
              do
                if [ $i != 0 ];then
                  error_exit "Could not create solo.rb_$ID.md5 check error output"
                fi
            done
 return 0
}
solo2s3 ()
{
aws ec2 run-instances --image-id $AMIID --key-name $KPNAME --security-group-ids $SECGRPID \
        --instance-type $INSTS --subnet-id $SBID --user-data file://user-data.sh --iam-instance-profile $IAM --output text 1>/tmp/Newinstance 2>/tmp/stderr

ID=`grep INSTANCES /tmp/Newinstance | awk 'BEGIN {FS=" "};{ print $8 }'`
#ID="i-345675"
 if [ -z $ID ];then
    error_exit "Instance ID Returned An Empty String Check /tmp/stderr"
 fi
       ok_cont "Instance ID was: $ID, Generating Solo Configs.."
       ok_cont "Generating solo.rb_$ID..."
       sed "s/instanceid/$ID/g" solo.rb > solo.rb_$ID || error_exit "Could not generate solo.rb_$ID check stdout"
       md5up "solo.rb_$ID"
         if [ "$?" = "0" ];then
           ok_cont "Created md5 file named solo.rb_$ID.md5"
         else
           error_exit "Could not create solo.rb_$ID.md5"
         fi
       aws s3 cp solo.rb_$ID.md5 s3://$BUCKET/solorb/ || error_exit "Could not copy solo.rb_$ID.md5 to S3 Bucket check stdout"
       aws s3 cp solo.rb_$ID s3://$BUCKET/solorb/ || error_exit "Could not copy solo.rb_$ID to S3 Bucket check stdout"
       ok_cont "solo.rb_$ID & solo.rb_$ID.md5 Were Generated and Copied to S3 Bucket!"
       cp $1.json $ID.json || error_exit "Could not rename base.json to $ID.json check stdout"
       md5up "$ID.json"
        if [ "$?" = "0" ];then
           ok_cont "Created md5 file named $ID.json.md5"
         else
           error_exit "Could not create $ID.json.md5"
         fi
       aws s3 cp $ID.json.md5 s3://$BUCKET/nodejson/ || error_exit "Could not copy $ID.json.md5 to S3 Bucket check stdout"
       aws s3 cp $ID.json s3://$BUCKET/nodejson/ || error_exit "Could not copy $ID.json to S3 Bucket check stdout"
       ok_cont "$ID.json & $ID.json.md5 Were Generated and Copied to S3 Bucket!"
       ok_cont "You should be good to go now :-) bye"
       mv solo.rb_$ID solorb/ 
       mv solo.rb_$ID.md5 solorb/
       mv $ID.json nodejson/
       mv $ID.json.md5 nodejson/
       return 0
}
case $CHEFR in 
 
  base)
       solo2s3 "base"
      ;; 
   web)
      solo2s3 "web"
      ;;
  esac

#Lets Clean 
cleanup
exit 0
