#!/bin/bash
#
# Script name:   concatenate_subjobs.sh
# Author:        Derek M. Shore, PhD
#
# This script creates/populates the directory './initial_structures' with n duplicate 
# structures, where n is the number of trajectories per swarm: `number_of_trajs_per_swarm`.
#
# This script is meant to be used at the onset of a new project, before any sampling has 
# taken place (so that all trajectories in the first swarm are really replicas). After 
# the first swarm is run, subsequent trajectories in subsequent swarms will NOT be replicas.  

# Usage: ./populate_initial_structures.sh

number_of_trajs_per_swarm=18
structure_file='dat_phase2b4.coor' # must be in ./common

# do not edit below this line

CWD=`pwd`
structure_file_path="$CWD/common/$structure_file"

mkdir -p initial_structures

for (( traj_number=0; traj_number<$number_of_trajs_per_swarm; traj_number++ ))
do
  traj_number_padded=`printf %04d $traj_number`
  cp $structure_file_path $CWD/initial_structures/${traj_number_padded}_initial_structure.pdb
done

exit
