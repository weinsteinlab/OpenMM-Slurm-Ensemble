#!/bin/bash -l

source ~/.bashrc

if [ $SLURM_JOB_PARTITION == "el8" ]; then
    conda activate openmm_7.5.1
else
    conda activate openmm_7_5_1
fi

subjob_number=$1

echo $SLURM_ARRAY_JOB_ID
echo "subjob #: "${subjob_number}

if [[ $subjob_number -gt 0 ]]
then
    finished=$(tail -n1 python_run.log)

    if [[ ! $finished ]] || [[ $finished != 'FINISHED' ]]
    then
        ((subjob_number--)) # decrement to refer to preceding subjob
        touch ../subjob_${subjob_number}_FAILED_traj${SLURM_ARRAY_JOB_ID}
        scancel $SLURM_JOB_ID 
        exit 1
    fi
fi

echo $subjob_number
python input.py $subjob_number $CUDA_VISIBLE_DEVICES > python_run.log
