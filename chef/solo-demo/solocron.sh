#!/bin/bash
#Will be executed by crontab every 20 min, chef is solo :-(
BUCKET="kiputch-solo"
REGION="us-east-1"
ROLES="roles/roles.tar.gz"
COOKBOOKS="cookbook/solo-all.tar.gz"
######################################
#Must Refactor this asap needs functions ... currently first version
###
exists() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}
exists "wget"
if [ "$?" == "0" ];then
  ID=$(wget -q -O- http://169.254.169.254/latest/meta-data/instance-id)
  SOLORB="solorb/solo.rb_${ID}"
  NODEJSON="nodejson/$ID.json"
else
  exit 3
fi
error_cont()
{
echo "`date`:ERROR $1"
}
locmd5()
{
  #Calc Local MD5 and Comp
  filemd5=$(md5sum $1 | awk 'BEGIN { FS=" " };{ print $1 }')
  for i in "${PIPESTATUS[@]}"
              do
                if [ $i != 0 ];then
                  error_cont "could not get md5sum for $1"
                fi
            done
   
 return 0
}
#solo.rb 
  aws s3 --region $REGION cp s3://$BUCKET/$SOLORB.md5 /etc/chef/ || error_cont "Could not update solo.rb_$ID.md5 from S3 Bucket $BUCKET"
  remmd5=$(cat /etc/chef/solo.rb_${ID}.md5)
  locmd5 "/etc/chef/solo.rb"
  if [ "$remmd5" == "$filemd5" ];then
    echo "MD5 are the same doing nada!"
  else
    #need to download file
    aws s3 --region $REGION cp s3://$BUCKET/$SOLORB /etc/chef/ || error_cont "Could not copy solo.rb_$ID fron S3 Bucket check stdout"
    chown root.root /etc/chef/solo.rb
  fi
#i-xxxxx.json
 aws s3 --region $REGION cp s3://$BUCKET/$NODEJSON.md5 /etc/chef/ || error_cont "Could not update $ID.json.md5 from S3 Bucket $BUCKET"
  remmd5=$(cat /etc/chef/${ID}.json.md5)
  locmd5 "/etc/chef/$ID.json"
  if [ "$remmd5" == "$filemd5" ];then
    echo "MD5 are the same doing nada!"
  else
    #need to download file
    aws s3 --region $REGION cp s3://$BUCKET/$NODEJSON /etc/chef/ || error_cont "Could not copy $ID.json fron S3 Bucket check stdout"
    chown root.root /etc/chef/$ID.json
  fi
#roles
 aws s3 --region $REGION cp s3://$BUCKET/$ROLES.md5 /var/chef-solo/roles/ || error_cont "Could not update $ROLES.md5 from S3 Bucket $BUCKET"
  remmd5=$(cat /var/chef-solo/roles/roles.tar.gz.md5)
  locmd5 "/var/chef-solo/roles/roles.tar.gz"
  if [ "$remmd5" == "$filemd5" ];then
    echo "MD5 are the same doing nada!"
  else
    #need to download file
    aws s3 --region $REGION cp s3://$BUCKET/$ROLES /var/chef-solo/roles/ || error_cont "Could not copy $ROLES fron S3 Bucket check stdout"
    chown root.root /var/chef-solo/roles.tar.gz
    cd /var/chef-solo/roles/
    tar xfz roles.tar.gz
  fi
#Cookbooks
  aws s3 --region $REGION cp s3://$BUCKET/$COOKBOOKS.md5 /var/chef-solo/cache/cookbooks/ || error_cont "Could not update $COOKBOOKS.md5 from S3 Bucket $BUCKET"
  remmd5=$(cat /var/chef-solo/cache/cookbooks/solo-all.tar.gz.md5)
  locmd5 "/var/chef-solo/cache/cookbooks/solo-all.tar.gz"
  if [ "$remmd5" == "$filemd5" ];then
    echo "MD5 are the same doing nada!"
  else
    #need to download file
    aws s3 --region $REGION cp s3://$BUCKET/$COOKBOOKS /var/chef-solo/cache/cookbooks/ || error_cont "Could not copy $ROLES fron S3 Bucket check stdout"
    chown root.root /var/chef-solo/cache/cookbooks/solo-all.tar.gz
    cd /var/chef-solo/cache/cookbooks/
    tar xfz solo-all.tar.gz
  fi 
#Now we are ready to run solo
/usr/bin/chef-solo -L /var/log/solorun.log
exit 0
