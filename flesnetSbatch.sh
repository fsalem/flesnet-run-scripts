#!/bin/bash
##SBATCH -A bzz0011
#SBATCH --exclusive
##SBATCH -C flat,quad
#SBATCH --time=00:30:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out
#SBATCH -p standard96:test

source env_variables.sh
export FI_PSM2_NAME_SERVER=1
export I_MPI_HYDRA_TOPOLIB=ipl
export I_MPI_FABRICS=ofa

echo "NODE_LIST=$SLURM_JOB_NODELIST"
# Get the addresses on the nodes
ADR=""
if [[ "1" -eq $USE_VERBS ]]; then
        ADR=$(srun -N $SLURM_JOB_NUM_NODES flesnetIBHosts.sh | sort -k1 -n | awk '{ print $1}')
        echo "ADD1=$ADR"
        ADR=($(sort <<<"${ADR[*]}"))
        echo "ADD2=$ADR"
        ADR=$( IFS=$' '; echo "${ADR[*]}" )
        echo "ADD3=$ADR"
else
        ADR=$(scontrol show hostnames | tr '\n' ' ')
fi


echo "Hostnames=\"$ADR\""


echo "# of nodes = $SLURM_JOB_NUM_NODES"
mkdir "jobs/$SLURM_JOB_ID"

if [ -z "$COMPUTE" ]; then
        INPUT=$((SLURM_JOB_NUM_NODES/2))
        COMPUTE=$((SLURM_JOB_NUM_NODES - INPUT))
fi

echo "COMPUTE=$COMPUTE, INPUT=$INPUT, ADR='$ADR'"
echo "Generating the Config file"
echo $(./generateFlesnetConfig.sh flesnet.cfg "$ADR" $INPUT $COMPUTE $IN_PER_NODE $CN_PER_NODE $SLURM_JOB_ID)
echo "flesnet.cfg is generated JOB_ID=$SLURM_JOB_ID"
IN_TASKS=$((INPUT*IN_PER_NODE))
CN_TASKS=$((COMPUTE*CN_PER_NODE))
TASKS=$IN_TASKS
if (( CN_TASKS > IN_TASKS )); then
    TASKS=$CN_TASKS
fi
#TASKS=$((TASKS*2))
TASKS=$((CN_TASKS+IN_TASKS))
echo "IN_TASKS=$IN_TASKS, CN_TASKS=$CN_TASKS, TASKS=$TASKS"
#IN_TASKS=$IN_TASKS CN_TASKS=$CN_TASKS SRUN=1 JOB_ID=$SLURM_JOB_ID HUGE_PAGES=$HUGE_PAGES srun -N $SLURM_JOB_NUM_NODES -n$TASKS ./flesnetRun2.sh
#IN_TASKS=$IN_TASKS CN_TASKS=$CN_TASKS SRUN=0 JOB_ID=$SLURM_JOB_ID HUGE_PAGES=$HUGE_PAGES mpirun -N 1 ./flesnetRun2.sh
SRUN=1 JOB_ID=$SLURM_JOB_ID INPUT=$INPUT COMPUTE=$COMPUTE  mpirun -np $SLURM_JOB_NUM_NODES -ppn 1 ./flesnetRun.sh
#wait


while true
do
        GREP_ERROR=$(grep -r "ERROR" jobs/$SLURM_JOB_ID/ | wc -l)
        GREP_SUMMARY=$(grep -r "summary:" jobs/$SLURM_JOB_ID/ | wc -l)
	#EXPECTED_SUMMARY=$((INPUT + COMPUTE + INPUT + COMPUTE))
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

mv job.$SLURM_JOB_ID.* *.input.*.out *.compute.*.out jobs/$SLURM_JOB_ID/
cp flesnet.cfg env_variables.sh jobs/$SLURM_JOB_ID/
wait

