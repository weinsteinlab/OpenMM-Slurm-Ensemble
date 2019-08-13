#!/bin/bash -l

spack load -r /62q4vgx # this is cuda@9.2.88

source ~/.bashrc
conda activate openmm_7.4_beta

python input.py $1 > python_run.log & 
