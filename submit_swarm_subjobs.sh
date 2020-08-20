#!/bin/bash -l

# use: this script is used by ./launch_swarm.sh and is not
# meant to be run directly.

swarm_number=$1
number_of_trajs_per_swarm=$2
#subjob_number=$3

# do not edit below this line

swarm_number_padded=`printf %04d $swarm_number`

CWD=`pwd`
swarm_path=$CWD/raw_swarms/swarm${swarm_number_padded}

prior_subjob_number=0
subjob_number=0
isPriorRun=$(ls ${CWD}/raw_swarms/swarm${swarm_number_padded}/swarm${swarm_number_padded}_traj0000/*subjob*.log 2> /dev/null | tail -n1 | wc -l)

traj_number_padded=`printf %04d $SLURM_ARRAY_TASK_ID`
traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded

if [ $isPriorRun == 1 ]; then
    full_name=$(ls ${traj_path}/*subjob*.log 2> /dev/null | tail -n1)
    padded_subjob_number=${full_name: -8:-4}
    subjob_number=$((10#$padded_subjob_number))
    prior_subjob_number=${subjob_number}
    ((subjob_number++))
fi

numberOfFinishedRuns=$(find ./prior_job_status/. -name "python_run_${prior_subjob_number}*.log" -exec tail -n1 {} \; | grep FINISHED | wc -l)

if [ $subjob_number -gt 0 ] && [ $numberOfFinishedRuns != $number_of_trajs_per_swarm ]
then
  ((subjob_number--))
  touch ./subjob_${subjob_number}_FAILED
  scancel -n $SBATCH_JOB_NAME
  exit 1
fi

cd $traj_path

./run_python.sh $subjob_number > ./python_log.txt 
