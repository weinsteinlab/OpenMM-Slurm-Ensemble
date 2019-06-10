#!/bin/bash
#
# Script name:   setup_individual_swarm.sh
# Author: Derek M. Shore, PhD
# 
# This script sets up the directory/file structure, for common files, 
# for an individual swarm. Here, a swarm is defined as a set of MD simulations
# that will have different starting structures after the first swarm is run.
#
# This script does NOT provide the starting structure--this is swarm-dependent, and is 
# controlled by other scripts.

# Use: ./setup_individual.sh 

swarm_number=0
number_of_trajs_per_swarm=18

# do not edit below this line

swarm_number_padded=`printf %04d $swarm_number`
CWD=`pwd`

swarm_path=$CWD/raw_swarms/swarm${swarm_number_padded}
mkdir -p $swarm_path

# we start with host_number 1 because 0 is the launch node
host_number=1

for (( traj_number=0; traj_number<$number_of_trajs_per_swarm; traj_number++ ))
do
  traj_number_padded=`printf %04d $traj_number`
  traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded

  mkdir $traj_path

  cp ./common/*.rtf $traj_path/.  
  cp ./common/*.psf $traj_path/.  
  cp ./common/*.py $traj_path/.
  cp ./common/*.prm $traj_path/.
  cp ./common/*.sh $traj_path/.

  # each node has 6 GPUs, so the following modulo makes sure each traj is assigned
  # is assigned a GPU # in the range 0-5.
  gpu_number=$(expr $traj_number % 6)
  cp ./common/gpu_${gpu_number}.erf $traj_path/.

  # Each host/node can accept 6 jobs, so after 6 jobs have been submitted,
  # the $host_number is incremented to start submitting on the subsequent node. 
  if [ $gpu_number == 0 ] && [ $traj_number != 0 ]; then ((host_number++)); fi
  sed -i "s/X/$host_number/" $traj_path/gpu_${gpu_number}.erf
done

exit
