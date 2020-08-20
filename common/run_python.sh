#!/bin/bash -l

source ~/.bashrc
conda activate openmm_7.4.0

subjob_number=$1

mass_and_parameter_files=\"$(echo 'all_masses.rtf", "'$(echo `ls *.prm` | sed 's/ /\", "/g'))\"
sed -i "s/parameterz/$mass_and_parameter_files/" ./readInputFiles.py

echo $SLURM_ARRAY_JOB_ID

#if [ $subjob_number -gt 0 ]
#then
#  finished=$(tail -n1 python_run.log)
#  
#   if [ $finished != 'FINISHED' ]
#   then
#     ((subjob_number--)) # decrement to refer to preceding subjob
#     touch ../subjob_${subjob_number}_FAILED
#     scancel $SLURM_ARRAY_JOB_ID 
#     exit 1
#   fi
#fi

python input.py $subjob_number > python_run.log
cp python_run.log ../../../prior_job_status/python_run_${subjob_number}_${SLURM_ARRAY_TASK_ID}.log
