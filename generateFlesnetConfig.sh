#!/bin/bash
FILENAME=$1 # filename of the config file
#echo "2 = $2"
IFS=' ' read -ra NODE_NAMES <<< "$2"


#echo "NODES = ${NODES[0]}, ${NODES[1]}, count=${#NODES[@]}, ARRAY=${NODES[@]}"
NINPUT=$3 # number of input nodes
NCOMP=$4 # number of output nodes
IN_PER_NODE=$5
CN_PER_NODE=$6
JOB_ID=$7
#BASE_PORT=$5 # base port to start with
#echo "NIMPUTS = $NINPUT, NCOMP = $NCOMP"

echo "NODE_NAMES=$NODE_NAMES, NINPUT=$NINPUT, NCOMP=$NCOMP, IN_PER_NODE=$IN_PER_NODE, CN_PER_NODE=$CN_PER_NODE, JOB_ID=$JOB_ID"
#echo "UNSORTED=$NODE_NAMES, SORTED $(NODE_NAMES | sort)"
I=0
echo -e "\n# The list of participating input nodes." > $FILENAME

for NODE in "${NODE_NAMES[@]}"
do
        #NODE_ADDR=$(./flesnetGetIPAddress.sh $NODE)
        NODE_ADDR=$NODE
        echo "Node= $NODE, NODE_ADDR=$NODE_ADDR"
        I=$((I+1))
        if [ "$I" -le "$NINPUT" ]; then
                COUNTER=0
                while [  $COUNTER -lt $IN_PER_NODE ]; do
                      echo "input = pgen://$NODE_ADDR/flesnet_0/" >> $FILENAME
                      let COUNTER=COUNTER+1
                done
        else
                COUNTER=0
                while [  $COUNTER -lt $CN_PER_NODE ]; do
                      echo "output = pgen://$NODE_ADDR/flesnet_0/" >> $FILENAME
                      let COUNTER=COUNTER+1
                done
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


#echo -e "# input node buffer size\n" >> $FILENAME
#echo -e "in-data-buffer-size-exp = $IN_BUF_SIZE\n\n" >> $FILENAME

#echo -e "# Compute node buffer size\n" >> $FILENAME
#echo -e "cn-data-buffer-size-exp = $CN_BUF_SIZE\n\n" >> $FILENAME

###scheduler data
echo -e "# The scheduler history size for statisctics\n" >> $FILENAME
echo -e "scheduler-history-size=$SCHEDULER_HISTORY_SIZE\n\n" >> $FILENAME

echo -e "# The scheduler minimum interval duration\n" >> $FILENAME
echo -e "scheduler-interval-length=$SCHEDULER_INTERVAL_LENGTH\n\n" >> $FILENAME

echo -e "# The scheduler maximum variance to speedup\n" >> $FILENAME
echo -e "scheduler-speedup-difference-percentage=$SCHEDULER_VARIANCE_LIMIT\n\n" >> $FILENAME

echo -e "# The scheduler speedup percentage\n" >> $FILENAME
echo -e "scheduler-speedup-percentage=$SCHEDULER_SPEEDUP_PERCENTAGE\n\n" >> $FILENAME

echo -e "# The scheduler speedup interval count\n" >> $FILENAME
echo -e "scheduler-speedup-interval-count=$SCHEDULER_SPEEDUP_INTERVAL_COUNT\n\n" >> $FILENAME

echo -e "# The directory to store log files\n" >> $FILENAME
echo -e "log-directory=$LOG_DIRECTORY/$JOB_ID\n\n" >> $FILENAME

echo -e "# Enable logging\n" >> $FILENAME
echo -e "enable-logging=$ENABLE_LOGGING\n\n" >> $FILENAME
cat flesnet.cfg.template >> $FILENAME
