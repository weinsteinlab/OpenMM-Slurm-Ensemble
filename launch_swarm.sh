#!/bin/bash
#
# Script name:   launch_swarm.sh
# Author:        Derek M. Shore, PhD
#
# This script launches a swarm of trajectories, with each trajectory consisting of 
# potentially many subjobs (to enable sampling that would not be possible within a 2-
# hour run limit).

# use: ./launch_swarm.sh

swarm_number=0
number_of_trajs_per_swarm=24
first_subjob=0
last_subjob=3
jobName="your_job_name" # no spaces

# do not edit below this line

first_iteration=0
number_of_nodes=`expr $number_of_trajs_per_swarm / 6`

for (( subjob=$first_subjob; subjob<=$last_subjob; subjob++ ))
do
  if [ $first_iteration -eq 0 ]
  then
    job_scheduler_output="$(bsub -P BIP180 -W 2:00 -nnodes $number_of_nodes -J $jobName -alloc_flags gpumps ./submit_swarm_subjobs.sh $swarm_number $number_of_trajs_per_swarm $subjob)"
  else
    job_scheduler_output="$(bsub -P BIP180 -W 2:00 -nnodes $number_of_nodes -J $jobName -alloc_flags gpumps -w $job_scheduler_number ./submit_swarm_subjobs.sh $swarm_number $number_of_trajs_per_swarm $subjob)"
  fi

  job_scheduler_number=$(echo $job_scheduler_output | awk '{print $2}' | sed -e 's/<//' | sed -e 's/>//')
  let first_iteration=1
done 

exit

