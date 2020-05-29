#!/bin/bash -l

#spack load -r /62q4vgx # this is cuda@9.2.88
module load gcc/8.1.0/1
module load cuda/10.1

source ~/.bashrc
conda activate openmm_7.4.0

subjob_number=$1

echo $SLURM_ARRAY_JOB_ID

if [ $subjob_number -gt 0 ]
then
  finished=$(tail -n1 python_run.log)
  
   if [ $finished != 'FINISHED' ]
   then
     ((subjob_number--)) # decrement to refer to preceding subjob
     touch ../subjob_${subjob_number}_FAILED
     scancel $SLURM_ARRAY_JOB_ID 
     exit 1
   fi
fi

python input.py $subjob_number > python_run.log
