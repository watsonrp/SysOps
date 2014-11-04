#!/bin/bash
wget -O /root/bootstrap.sh https://YOU-S3-BUCKET-NAME.s3.amazonaws.com/others/bootstrap.sh
cd /root
chmod +x bootstrap.sh
./bootstrap.sh
