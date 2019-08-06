#!/bin/bash
#
# Script name:   setup_individual_swarm.sh
# Author: Derek M. Shore, PhD
# 
# This script sets up the directory/file structure, for common files, 
# for an individual swarm. Here, a swarm is defined as a set of MD simulations
# that will have different starting structures after the first swarm is run.

# Use: ./setup_individual.sh 

swarm_number=0
number_of_trajs_per_swarm=24

# do not edit below this line

swarm_number_padded=`printf %04d $swarm_number`
CWD=`pwd`

swarm_path=$CWD/raw_swarms/swarm${swarm_number_padded}
mkdir -p $swarm_path

# we start with host_number 1 because 0 is the launch node
host_number=1

# starting with input directory '0000'
directoryNumber=0
directoryNumberPadded=`printf %04d $directoryNumber`
currentNumberOfReplicas=$(cat ./inputs/${directoryNumberPadded}/numberOfReplicas.txt)


for (( traj_number=0; traj_number<$number_of_trajs_per_swarm; traj_number++ ))
do
  traj_number_padded=`printf %04d $traj_number`
  traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded

  mkdir $traj_path
  cp ./common/readInputFiles.py $traj_path/.
  cp ./common/run_python.sh $traj_path/.
  cp ./inputs/${directoryNumberPadded}/*.* $traj_path/.
  ((currentNumberOfReplicas--))

  if [ $currentNumberOfReplicas -eq 0] 
  then
    ((directoryNumber++))
    directoryNumberPadded=`printf %04d $directoryNumber`
    currentNumberOfReplicas=$(cat inputs/${directoryNumberPadded}/numberOfReplicas.txt)
  fi
     
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
