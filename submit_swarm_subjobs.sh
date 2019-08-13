#!/bin/bash -l

# use: this script is used by ./launch_swarm.sh and is not
# meant to be run directly.

swarm_number=$1
number_of_trajs_per_swarm=$2
subjob_number=$3

# do not edit below this line

swarm_number_padded=`printf %04d $swarm_number`
subjob_number_padded=`printf %04d $subjob_number`

CWD=`pwd`
swarm_path=$CWD/raw_swarms/swarm${swarm_number_padded}


traj_number_padded=`printf %04d $SLURM_ARRAY_TASK_ID`
traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded

cd $traj_path

./run_python $subjob_number > ./python_log.txt 
