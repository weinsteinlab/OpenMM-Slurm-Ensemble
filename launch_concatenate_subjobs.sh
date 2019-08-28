#!/bin/bash -l
#SBATCH -p edison                   # partition name
#SBATCH -t 0-02:00:00               # days-hours:minutes:seconds
#SBATCH -N1                         # number of nodes 
#SBATCH -n1                         # number of processes
#SBATCH --mem=40G                   # memory
#SBATCH -J concatenate_subjobs      # job name

swarm_number=0
number_of_trajs_per_swarm=40
catdcd="/home/des2037/vmd3/lib/vmd3/plugins/LINUXAMD64/bin/catdcd5.1/catdcd"

# do not edit below this line

./concatenate_subjobs.sh $swarm_number $number_of_trajs_per_swarm $catdcd > log_concatenate_subjobs.txt 

exit

