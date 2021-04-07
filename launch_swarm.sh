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
number_of_gpus_per_replica=1 # note: this should be 1 unless your system is > 500,000 atoms

jobName="test" # no spaces
partitionName=dcs            #Slurm partition to run job on

# do not edit below this line

firstIteration=0
numberOfNodes=$((numberOfTrajsPerSwarm*number_of_gpus_per_replica/6))
swarmNumber_padded=`printf %04d $swarmNumber`
fullJobName=${jobName}_swarm${swarmNumber_padded}


for (( subjob=0; subjob<$number_of_jobs; subjob++ ))
do
  if [ $firstIteration -eq 0 ]
  then
     job_scheduler_output="$(sbatch -J $jobName -N ${numberOfNodes} -p $partitionName --gres=gpu:32g:6 -C cuda-mode-exclusive -t 0-02:00:00 -o ./raw_swarms/submission_logs/${fullJobName}_slurm-%A.out ./submit_swarm_subjobs.sh $swarmNumber $numberOfTrajsPerSwarm $number_of_gpus_per_replica)"       
  else
     job_scheduler_output="$(sbatch --depend=afterok:${job_scheduler_number} -J $jobName -N ${numberOfNodes} -p $partitionName --gres=gpu:32g:6 -C cuda-mode-exclusive -t 0-02:00:00 -o ./raw_swarms/submission_logs/${fullJobName}_slurm-%A.out ./submit_swarm_subjobs.sh $swarmNumber $numberOfTrajsPerSwarm $number_of_gpus_per_replica)" 
  fi

  job_scheduler_number=$(echo $job_scheduler_output | awk '{print $4}')
  let firstIteration=1
done

exit

