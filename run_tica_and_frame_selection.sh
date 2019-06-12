#!/bin/bash -l

module load xl
module load fftw
module load cuda/10.1.105

source ~/.bashrc
source activate tica_env

python python tica_and_frame_selection.py > log_tica_and_frame_selection.txt

exit
