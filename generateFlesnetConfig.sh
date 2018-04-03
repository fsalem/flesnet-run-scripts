#!/bin/bash
FILENAME=$1 # filename of the config file
#echo "2 = $2" 
IFS=' ' read -ra NODE_NAMES <<< "$2"


#echo "NODES = ${NODES[0]}, ${NODES[1]}, count=${#NODES[@]}, ARRAY=${NODES[@]}"
NINPUT=$4 # number of input nodes
NCOMP=$3 # number of output nodes
#BASE_PORT=$5 # base port to start with
#echo "NIMPUTS = $NINPUT, NCOMP = $NCOMP"


I=0
echo -e "\n# The list of participating input nodes." > $FILENAME

for NODE in "${NODE_NAMES[@]}"
do
	NODE_ADDR=$(./flesnetGetIPAddress.sh $NODE)
	echo "Node= $NODE, NODE_ADDR=$NODE_ADDR"
	I=$((I+1))
	if [ "$I" -le "$NINPUT" ]; then
		echo "input-nodes = $NODE_ADDR" >> $FILENAME
	else
		echo "compute-nodes = $NODE_ADDR" >> $FILENAME
	fi
	
	if [ "$I" -eq "$NINPUT" ]; then
		echo -e "\n# The list of participating compute nodes." >> $FILENAME
	fi
done 
#fi

source env_variables.sh

echo -e "\n\n" >> $FILENAME
echo -e "base-port = $BASE_PORT\n\n" >> $FILENAME
echo -e "# The global timeslice size in number of MCs.\n" >> $FILENAME
echo -e "timeslice-size = $TIMESLICE_SIZE\n\n" >> $FILENAME


echo -e "# input node buffer size\n" >> $FILENAME
echo -e "in-data-buffer-size-exp = $IN_BUF_SIZE\n\n" >> $FILENAME

echo -e "# Compute node buffer size\n" >> $FILENAME
echo -e "cn-data-buffer-size-exp = $CN_BUF_SIZE\n\n" >> $FILENAME

cat flesnet.cfg.template >> $FILENAME
