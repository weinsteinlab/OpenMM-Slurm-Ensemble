#!/bin/bash
# This script is submitted as a single job by 'launch_swarm.sh'.
# It will submit the actual Slurm array job, then wait for it to complete before exiting.

swarmNumber=$1
numberOfTrajsPerSwarm=$2
jobName=$3
partitionName=$4

swarmNumber_padded=$(printf %04d $swarmNumber)
fullJobName=${jobName}_swarm${swarmNumber_padded}
indexed_num_of_trajs=$((numberOfTrajsPerSwarm - 1))

outputDir="./raw_swarms/submission_logs"
mkdir -p "${outputDir}"

echo "Submitting array job for swarmNumber=${swarmNumber}, numberOfTrajsPerSwarm=${numberOfTrajsPerSwarm}..."

# Submit the array job
job_scheduler_output="$(sbatch \
  -J ${jobName} \
  -N1 -n1 \
  -p ${partitionName} \
  --cpus-per-task=6 \
  --gres=gpu:1 \
  -t 0-06:00:00 \
  -o ${outputDir}/${fullJobName}_slurm-%A_%a.out \
  --array=0-${indexed_num_of_trajs} \
  ./submit_swarm_subjobs.sh ${swarmNumber} ${numberOfTrajsPerSwarm})"

# Extract the array job ID
array_job_id=$(echo $job_scheduler_output | awk '{print $4}')

if [ -z "$array_job_id" ]; then
  echo "Failed to submit array job."
  exit 1
fi

echo "Submitted array job: ${array_job_id}. Waiting for it to complete..."

# Wait until the array job no longer appears in the queue
while squeue -j ${array_job_id} | grep -q "${array_job_id}"; do
    sleep 10
done


if scontrol show job ${array_job_id} | grep "ExitCode=" | grep -qv "ExitCode=0:0"; then
    exit 1  # At least one exit code is not 0:0
else
    exit 0  # All exit codes are 0:0
fi


