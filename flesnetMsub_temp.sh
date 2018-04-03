#!/bin/bash
#MSUB -e job$MOAB_JOBID.err
#MSUB -o job$MOAB_JOBID.out
#MSUB -l walltime=00:40:00
##MSUB -l feature='c0-0c1'
##||c0-0c0'
##MSUB -l nodes='31:c0-0c0+1:c0-0c1s8n1'

source env_variables_temp.sh

if [ -z "$COMPUTE" ]; then
	INPUT=$((PBS_NUM_NODES/2))
	COMPUTE=$((PBS_NUM_NODES - INPUT))
fi

mkdir "jobs/$MOAB_JOBID"
PES_PER_NODE=$((INPUT + COMPUTE))
PES_COUNT=$((PES_PER_NODE * PBS_NUM_NODES))
echo "COMPUTE=$COMPUTE, INPUT=$INPUT"
echo "Generating the Config file"
hostnames=$(aprun -N1 -n$PBS_NUM_NODES ./flesnetMsubHosts.sh | sort -k1 -n | awk '{ print $2}')
echo "hostnames=$hostnames"
I=0
FILENAME="flesnet.cfg"
echo -e "\n# The list of participating compute and Input nodes." > $FILENAME

for hostname in $hostnames
do
	if [[ $hostname != nid* ]]; then
		#echo "cur HOST=$hostname"
		continue
	fi
	if [ "$I" -eq "$PBS_NUM_NODES" ]; then
		break
	fi

#    grepRes=$(grep $hostname /etc/hosts)
    NODE_ADDR=$(./flesnetGetIPAddress.sh $hostname)
    echo "NODE_ADDR=$NODE_ADDR , hostname=$hostname"
#    for ip in $grepRes
#    do
#    	NODE_ADDR=$ip
#    	break
#    done
    I=$((I+1))
    if [ "1" -eq "$MULTI" ]; then
    	for com in `seq 1 $COMPUTE`
    	do
    		echo "compute-nodes = $NODE_ADDR" >> $FILENAME
    	done
    	for in in `seq 1 $INPUT`
    	do
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME
    	done
    else
    	if [ "$I" -le "$INPUT" ]; then
    		echo "input-nodes = $NODE_ADDR" >> $FILENAME
		else
			echo "compute-nodes = $NODE_ADDR" >> $FILENAME
		fi
	fi
done

echo -e "\n\n" >> $FILENAME

echo -e "base-port = $BASE_PORT \n\n" >> $FILENAME

echo -e "# The global timeslice size in number of MCs.\n" >> $FILENAME
echo -e "timeslice-size = $TIMESLICE_SIZE\n\n" >> $FILENAME


echo -e "# input node buffer size\n" >> $FILENAME
echo -e "in-data-buffer-size-exp = $IN_BUF_SIZE\n\n" >> $FILENAME

echo -e "# Compute node buffer size\n" >> $FILENAME
echo -e "cn-data-buffer-size-exp = $CN_BUF_SIZE\n\n" >> $FILENAME
cat flesnet_temp.cfg.template >> $FILENAME

echo "flesnet.cfg is generated JOB_ID=$MOAB_JOBID"

if [ "1" -eq "$MULTI" ]; then
	MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N$PES_PER_NODE -n$PES_COUNT -F exclusive -d 5 ./flesnetRun_temp.sh & # > output.out 2>&1
else
	MULTI=$MULTI COMPUTE=$COMPUTE INPUT=$INPUT SRUN=0 JOB_ID=$MOAB_JOBID HUGE_PAGES=$HUGE_PAGES aprun -N1 -n$PBS_NUM_NODES -F exclusive -d 5 -cc depth ./flesnetRun_temp.sh # > output.out 2>&1
fi
while true
do
	GREP_ERROR=$(grep -r "ERROR" jobs/$MOAB_JOBID/ | wc -l)
	GREP_SUMMARY=$(grep -r "summary:" jobs/$MOAB_JOBID/ | wc -l)
	if [ "$GREP_SUMMARY" -gt "0" ] ; then
		echo "GREP_SUMMARY=$GREP_SUMMARY and GREP_ERROR=$GREP_ERROR"
		break
	fi
	if [ "$GREP_ERROR" -gt "0" ] ; then
                echo "GREP_ERROR=$GREP_ERROR"
		mjobctl -r $JOB_ID
                break
        fi
	sleep 30
done 
wait

aprun -N1 -n$PBS_NUM_NODES -F exclusive ./flesnetCleanAprun.sh
wait

