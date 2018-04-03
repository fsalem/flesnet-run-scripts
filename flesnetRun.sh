#!/bin/bash

export ATP_ENABLED=1
#export FI_LOG_LEVEL=DEBUG
#export LOG_LEVEL=DEBUG
#export FI_LOG_LEVEL=WARN
#export LOG_LEVEL=WARN
PROCID=-1
export HUGETLB_VERBOSE=2
if [ "$SRUN" -eq "1" ]; then
	PROCID=$SLURM_PROCID
else
	module load craype-hugepages$HUGE_PAGES
	PE_VAR=$(env|grep "ALPS_APP_PE")
	PROC_STR=(${PE_VAR//=/ })
	PROCID=${PROC_STR[1]}
fi

if [ "1" -eq "$MULTI" ]; then
	total=$((COMPUTE + INPUT))
	remainder=$((PROCID % total))
	iteration=$((PROCID / total))
	#echo "remainder=$remainder, total = $total, iteration = $iteration"
	if [ $remainder -lt $INPUT ]; then
		sleep 30s
		INPUT_ID=$(((iteration * INPUT) + remainder))
		./flesnet -i $INPUT_ID >> jobs/$JOB_ID/$INPUT_ID.input.out 2>&1
	else 
		COMPUTE_ID=$(((iteration * COMPUTE) + (remainder-INPUT)))
		./flesnet -c $COMPUTE_ID >> jobs/$JOB_ID/$COMPUTE_ID.compute.out 2>&1
	fi
else
	NODE_ADDR=$(./flesnetGetIPAddress.sh $hostname)
	COMPUTE_ID=$(grep "compute-nodes = " flesnet.cfg | grep -n $NODE_ADDR  | tr ":" " " | awk '{ print $1-1}')
	INPUT_ID=$(grep "input-nodes = " flesnet.cfg | grep -n $NODE_ADDR | tr ":" " " | awk '{ print $1-1}')
	#echo "NODE_ADDR=$NODE_ADDR, COMPUTE_ID=$COMPUTE_ID, ${COMPUTE_ID[0]}, INPUT_ID=$INPUT_ID, ${INPUT_ID[0]}"
	if [[ ! -z $INPUT_ID ]]; then
		echo "NODE_ADDR=$NODE_ADDR, INPUT_ID=${INPUT_ID[0]}"
               #sleep 10s
               ./flesnet -i ${INPUT_ID[0]} >> jobs/$JOB_ID/${INPUT_ID[0]}.input.out 2>&1
       else
		if [[ ! -z $COMPUTE_ID ]]; then 
			#source env_variables.sh
			#BASE_PORT=$((BASE_PORT + COMPUTE_ID[0]))
			#LSOF_CMD="netstat -lnt | awk '$6 == \"LISTEN\" && $4 ~ \".$BASE_PORT\"'"
                	#LSOF_CMD="lsof -Pi :$BASE_PORT"
			#LSOF_RES=$($LSOF_CMD)
			#echo "in ${COMPUTE_ID[0]} with port $BASE_PORT, LSOF_CMD=$LSOF_CMD LSOF_RES = $LSOF_RES"
			echo "NODE_ADDR=$NODE_ADDR, COMPUTE_ID=${COMPUTE_ID[0]}"
               		./flesnet -c ${COMPUTE_ID[0]} >> jobs/$JOB_ID/${COMPUTE_ID[0]}.compute.out 2>&1
		fi
       fi

#	if [ $PROCID -lt $INPUT ]; then
#		sleep 10s
#		./flesnet -i $PROCID >> jobs/$JOB_ID/$PROCID.input.out 2>&1
#	else 
#		COMP_ID=$((PROCID - INPUT))
#		./flesnet -c $COMP_ID >> jobs/$JOB_ID/$COMP_ID.compute.out 2>&1
#	fi
fi
wait
echo "NODE_ADDR=$NODE_ADDR is done"
