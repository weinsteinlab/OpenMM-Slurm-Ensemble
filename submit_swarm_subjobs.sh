#!/bin/bash
## Begin LSF Directives
#BSUB -P BIP180			# project name
#BSUB -W 0:15			# hours:minutes, with 2 hour maximum
#BSUB -nnodes 3 		# this should equal: number_of_trajs_per_swarm/6 
#BSUB -J openMM_test_ensemble   # job name
#BSUB -alloc_flags gpumps

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
  traj_path=$swarm_path/swarm${swarm_number_padded}_trajs$traj_number_padded
  
  if [[ "$swarm_number" -eq 0 ]]; then
    cp $CWD/initial_structures/${traj_number_padded}*.pdb $traj_path/.
  else
    prior_swarm_number="$(expr $swarm_number - 1)"
    prior_swarm_number_padded=`printf %04d $prior_swarm_number`
    cp $CWD/selected_frames/sel_frames_swarm_$prior_swarm_number_padded/${traj_number_padded}*.pdb $traj_path/.
  fi

  starting_structure=$(ls ${traj_path}/${traj_number_padded}*.pdb)
  erf_file=$(ls ${traj_path}/*.erf)

  cd $traj_path
  jsrun --erf_input $erf_file ./run_python.sh $swarm_number $traj_number $starting_structure $subjob_number &
  cd $CWD
done 