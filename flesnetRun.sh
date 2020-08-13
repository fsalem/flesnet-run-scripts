#!/bin/bash

#export ATP_ENABLED=1
#export FI_LOG_LEVEL=DEBUG
export LOG_LEVEL=DEBUG

#export FI_LOG_LEVEL=WARN
#export LOG_LEVEL=WARN

export FI_PSM2_NAME_SERVER=1
export I_MPI_HYDRA_TOPOLIB=ipl
export I_MPI_FABRICS=ofa

export PSM2_MQ_SENDREQS_MAX=16777216
export PSM2_MQ_RECVREQS_MAX=16777216
export PSM2_MEMORY=large
echo "hostname=$(hostname)"

PROCID=-1

#echo "SLURM_PROCID=$SLURM_PROCID, OMPI_COMM_WORLD_RANK=$OMPI_COMM_WORLD_RANK, IP=$(./flesnetIBHosts.sh)"
if [ "$SRUN" -eq "1" ]; then
        PROCID=$SLURM_PROCID
else
        PROCID=$OMPI_COMM_WORLD_RANK
fi

NODE_ADDR=$(./flesnetGetIPAddress.sh)
echo "NODE_ADDR=$NODE_ADDR hostname=$(hostname)"
COMPUTE_ID=$(grep "output = " flesnet.cfg | grep -n "$NODE_ADDR/"  | tr ":" " " | awk '{ print $1-1}')
INPUT_ID=$(grep "input = " flesnet.cfg | grep -n "$NODE_ADDR/" | tr ":" " " | awk '{ print $1-1}')
echo "NODE_ADDR=$NODE_ADDR, COMPUTE_ID=$COMPUTE_ID, ${COMPUTE_ID[0]}, INPUT_ID=$INPUT_ID, ${INPUT_ID[0]}"
if [[ ! -z $INPUT_ID ]]; then
	ID=${INPUT_ID[0]}
        echo "NODE_ADDR=$NODE_ADDR, INPUT_ID=${INPUT_ID[0]}, ID=$ID"
        #sleep 10s
        export FI_PSM2_DISCONNECT=1
	FILE_NAME="jobs/$JOB_ID/$ID.input.out"
        echo "redirect input to $FILE_NAME"
	cmd="stdbuf -i0 -o0 -e0 ./flesnet -f flesnet.cfg -i $ID >> $FILE_NAME 2>&1"
	eval $cmd
else
       if [[ ! -z $COMPUTE_ID ]]; then
		ID=${COMPUTE_ID[0]}
                echo "NODE_ADDR=$NODE_ADDR, COMPUTE_ID=${COMPUTE_ID[0]}, ID=$ID"
                export FI_PSM2_DISCONNECT=0
		FILE_NAME="jobs/$JOB_ID/$ID.compute.out"
                echo "redirect compute to $FILE_NAME"
		cmd="stdbuf -i0 -o0 -e0 ./flesnet -f flesnet.cfg -o $ID >> $FILE_NAME 2>&1"
		eval $cmd
       fi
fi

wait
