#!/bin/bash -l

# use: this script is used by ./launch_swarm.sh and is not
# meant to be run directly.

swarm_number=$1
number_of_trajs_per_swarm=$2

swarm_number_padded=`printf %04d $swarm_number`
CWD=`pwd`
swarm_path=$CWD/raw_swarms/swarm${swarm_number_padded}

traj_number_padded=`printf %04d $SLURM_ARRAY_TASK_ID`
traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded

numberOfFinishedRuns=$(find ${traj_path} -name 'python_run.log' -exec tail -n1 {} \; | grep FINISHED | wc -l)

subjob_number=0
isPriorRun=$(ls ${CWD}/raw_swarms/swarm${swarm_number_padded}/swarm${swarm_number_padded}_traj${traj_number_padded}/*subjob*.log 2> /dev/null | tail -n1 | wc -l)

if [ $isPriorRun == 1 ]; then
    full_name=$(ls ${CWD}/raw_swarms/swarm${swarm_number_padded}/swarm${swarm_number_padded}_traj${traj_number_padded}/*subjob*.log 2> /dev/null | tail -n1)
    padded_subjob_number=${full_name: -8:-4}
    subjob_number=$((10#$padded_subjob_number))
    ((subjob_number++))
fi

if [ $subjob_number -gt 0 ] && [ $numberOfFinishedRuns != 1 ]
then
  ((subjob_number--))
  touch ./subjob_${subjob_number}_FAILED
  scancel $SLURM_JOB_ID
  exit 1
fi

cd $traj_path

./run_python.sh $subjob_number > ./python_log.txt 
