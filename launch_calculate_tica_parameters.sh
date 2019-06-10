#!/bin/bash
## Begin LSF Directives
#BSUB -P BIP180                           # project name
#BSUB -W 0:30                             # hours:minutes, with 2 hour maximum
#BSUB -nnodes 1                          
#BSUB -J test_calculate_tica_parameters   # job name

jsrun -n1 -c1 python calculate_tica_parameters.py > log_tica_parameters_calc.txt

exit

