#!/bin/bash
#
# Script name:   launch_swarm.sh
# Author:        Derek M. Shore, PhD
#
# This script launches a swarm of trajectories, with each trajectory consisting of 
# potentially many subjobs (to enable sampling that would not be possible within a 2-
# hour run limit).

# use: ./launch_swarm.sh

swarmNumber=0
numberOfTrajsPerSwarm=6
number_of_jobs=2

jobName="openMM_test_ensemble" # no spaces
#partitionName="el8"            # Slurm partition for RPI
partitionName="hwlab-rocky-gpu,scu-gpu"  

# do not edit below this line

firstIteration=0
swarmNumber_padded=`printf %04d $swarmNumber`
fullJobName=${jobName}_swarm${swarmNumber_padded}
indexed_num_of_trajs=$((numberOfTrajsPerSwarm-1))


for (( subjob=0; subjob<${number_of_jobs}; subjob++ ))
do
  if [ $firstIteration -eq 0 ]
  then
     job_scheduler_output="$(sbatch -J $jobName -N1 -n1 -p $partitionName --cpus-per-task=6 --gres=gpu:1 -t 0-06:00:00 -o ./raw_swarms/submission_logs/${fullJobName}_slurm-%A_%a.out --array=0-${indexed_num_of_trajs} ./submit_swarm_subjobs.sh $swarmNumber $numberOfTrajsPerSwarm)"       
  else
     sleep 3
     job_scheduler_output="$(sbatch --depend=afterok:${job_scheduler_number} -J $jobName -N1 -n1 -p $partitionName --cpus-per-task=6 --gres=gpu:1 -t 0-06:00:00 -o ./raw_swarms/submission_logs/${fullJobName}_slurm-%A_%a.out --array=0-${indexed_num_of_trajs} ./submit_swarm_subjobs.sh $swarmNumber $numberOfTrajsPerSwarm)" 
  fi

  job_scheduler_number=$(echo $job_scheduler_output | awk '{print $4}')
  let firstIteration=1
done

exit

