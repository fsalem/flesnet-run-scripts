#!/bin/bash


hostname=$(hostname)
if [ $# -eq 1 ]
  then
    hostname=$1
fi

grepRes=$(grep $hostname /etc/hosts)
NODE_ADDR=""
for ip in $grepRes
do
	NODE_ADDR=$ip
    break
done


echo $NODE_ADDR
