#!/bin/bash



#grepRes=$(nslookup $hostname | awk '{ if (NR==5) print $2 }')
grepRes=$(/sbin/ip addr show ib0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
#$(grep $hostname /etc/hosts)
NODE_ADDR=""
for ip in $grepRes
do
    NODE_ADDR=$ip
    break
done

echo $NODE_ADDR
