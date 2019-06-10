#!/bin/bash
#
# Script name:   concatenate_subjobs.sh
# Author:        Derek M. Shore, PhD

# use: this script is used by ./launch_concatenate_subjobs.sh and is not
# meant to be run directly.

swarm_number=$1
number_of_trajs_per_swarm=$2
catdcd=$3
structure_file=$4 

CWD=`pwd`
swarm_number_padded=`printf %04d $swarm_number`
swarm_path=$CWD/raw_swarms/swarm$swarm_number_padded
swarm_concatenated_path=$CWD/swarms_concatenated_temp/$swarm_number_padded
structure_file_path="$CWD/common/$structure_file"

mkdir -p $swarm_concatenated_path

for (( traj_number=0; traj_number<$number_of_trajs_per_swarm; traj_number++ ))
do
  traj_number_padded=`printf %04d $traj_number`
  traj_path=$swarm_path/swarm${swarm_number_padded}_traj$traj_number_padded
  cd $traj_path
  $catdcd -o $swarm_concatenated_path/${traj_number_padded}.trr -otype trr -s $structure_file_path *.dcd
done

exit
