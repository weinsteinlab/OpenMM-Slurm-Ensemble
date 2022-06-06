#!/bin/bash -l

source ~/.bashrc

if [ $SLURM_JOB_PARTITION == "el8" ]; then
    conda activate openmm_7.5.1
else
    conda activate openmm_7_5_1
fi

subjob_number=$1

echo $SLURM_ARRAY_JOB_ID

if [ $subjob_number -gt 0 ]
then
    finished=$(tail -n1 python_run.log)
  
    if [ $finished != 'FINISHED' ]
    then
        ((subjob_number--)) # decrement to refer to preceding subjob
        touch ../subjob_${subjob_number}_FAILED_traj${SLURM_ARRAY_JOB_ID}
        scancel $SLURM_ARRAY_JOB_ID 
        exit 1
    fi
fi

python input.py $subjob_number > python_run.log
