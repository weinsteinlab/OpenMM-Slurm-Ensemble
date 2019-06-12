#!/bin/bash
## Begin LSF Directives
#BSUB -P BIP180                           # project name
#BSUB -W 0:30                             # hours:minutes, with 2 hour maximum
#BSUB -nnodes 1                          
#BSUB -J test_calculate_tica_parameters   # job name

jsrun -n1 -c1 ./run_calculate_tica_parameters.sh > log_calculate_tica.txt

exit

