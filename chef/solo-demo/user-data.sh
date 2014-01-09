#!/bin/bash
wget -O /root/bootstrap.sh https://s3.amazonaws.com/kiputch-solo/others/bootstrap.sh
cd /root
chmod +x bootstrap.sh
./bootstrap.sh
