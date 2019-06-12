#!/bin/bash
## Begin LSF Directives
#BSUB -P BIP180                     # project name
#BSUB -W 0:30                       # hours:minutes, with 2 hour maximum
#BSUB -nnodes 1                     # this should equal: number_of_trajs/6 
#BSUB -J test_concatenate_subjobs   # job name

swarm_number=0
number_of_trajs_per_swarm=18
catdcd="/gpfs/alpine/proj-shared/bip180/vmd/vmd_library/plugins/OPENPOWER/bin/catdcd5.1/catdcd"
structure_file='dat_phase2b4.coor' # must be in ./common

# do not edit below this line

jsrun -n1 -c1 ./concatenate_subjobs.sh $swarm_number $number_of_trajs_per_swarm $catdcd $structure_file > log_concatenate_subjobs.txt 

exit

