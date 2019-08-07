#!/bin/bash

# use: this script is used by ./launch_swarm.sh and is not
# meant to be run directly.

swarm_number=$1
number_of_trajs_per_swarm=$2
subjob_number=$3

# do not edit below this line

swarm_number_padded=`printf %04d $swarm_number`

CWD=`pwd`
swarm_path=$CWD/raw_swarms/swarm${swarm_number_padded}

for ((traj_number=0; traj_number<$number_of_trajs_per_swarm; traj_number++))
do
  traj_number_padded=`printf %04d $traj_number`
  traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded
  
  erf_file=$(ls ${traj_path}/*.erf)

  cd $traj_path
  jsrun --smpiargs="none" --erf_input $erf_file ./run_python.sh $subjob_number &
  cd $CWD
done 
