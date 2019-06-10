#!/bin/bash
## Begin LSF Directives
#BSUB -P BIP180                           # project name
#BSUB -W 0:30                             # hours:minutes, with 2 hour maximum
#BSUB -nnodes 1                          
#BSUB -J test_tica_and_frame_selection    # job name

jsrun -n1 -c1 python tica_and_frame_selection.py > log_tica_and_frame_selection.txt

exit

