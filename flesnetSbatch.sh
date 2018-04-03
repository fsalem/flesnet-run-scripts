#!/bin/bash
##BATCH -A <account>
#SBATCH --exclusive
#SBATCH --time=00:30:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out
#SBATCH -C c0-0c1

##feature='c0-0c1||c0-0c0'
#nodes='31:c0-0c0+1:c0-0c1s8n1'

source env_variables.sh

# Get the addresses on the nodes
ADR=$(scontrol show hostnames | tr '\n' ' ')
echo "Hostnames=$ADR"


echo "# of nodes = $SLURM_JOB_NUM_NODES"
mkdir "jobs/$SLURM_JOB_ID"

if [ -z "$COMPUTE" ]; then
	INPUT=$((SLURM_JOB_NUM_NODES/2))
	COMPUTE=$((SLURM_JOB_NUM_NODES - INPUT))
fi

echo "COMPUTE=$COMPUTE, INPUT=$INPUT"
echo "Generating the Config file"
echo $(./generateFlesnetConfig.sh flesnet.cfg "$ADR" $COMPUTE $INPUT)
echo "flesnet.cfg is generated JOB_ID=$SLURM_JOB_ID"

MULTI=0 COMPUTE=$COMPUTE INPUT=$INPUT SRUN=1 JOB_ID=$SLURM_JOB_ID HUGE_PAGES=$HUGE_PAGES srun -N $SLURM_JOB_NUM_NODES ./flesnetRun.sh
#wait


while true
do
        GREP_ERROR=$(grep -r "ERROR" jobs/$SLURM_JOB_ID/ | wc -l)
        GREP_SUMMARY=$(grep -r "summary:" jobs/$SLURM_JOB_ID/ | wc -l)
        if [ "$GREP_SUMMARY" -gt "0" ] ; then
                echo "GREP_SUMMARY=$GREP_SUMMARY and GREP_ERROR=$GREP_ERROR"
                break
        fi
        if [ "$GREP_ERROR" -gt "0" ] ; then
                echo "GREP_ERROR=$GREP_ERROR"
                scancel $SLURM_JOB_ID
                break
        fi
        sleep 30
done
wait

srun -N $SLURM_JOB_NUM_NODES ./flesnetClean.sh
wait

