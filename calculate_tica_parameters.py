import os,sys
import numpy as np
from utils import vmd_cal_parms
from tica import *


"""
NOTES:

1. Analyses are in the "analysis" folder
2. tICA parameters are saved as "analysis/tica_parameters/swarm%d_traj%d.npy" %(swarm_id, traj_id)
3. tICA landscape, along with location of selected frames to start new simulaitons will be saved as images in `analysis` folder.
4. pdb files to start new swarms with are saved at: `./selected_frames/sel_frames_swarm_0000`, `selected_frames/sel_frames_swarm_0001`, etc.
"""

#-------------------input parameters ----------------------------------------
vmd_path = "/gpfs/alpine/proj-shared/bip180/vmd/vmd_bin/vmd"
psf_path = "./common/ionized.psf"
pdb_path = "./common/hdat_3_1_restart_coor.pdb"
tica_lag_time = 5			# 5 steps
n_clusters = 18				# number of clusters for tICA landscape
n_sel_clusters = 6			# number of low-populated clusters that frames for new swarms will be taken from
n_sel_frames = 3			# number of frames to extract from each `n_sel_clusters`
total_n_of_swarms = 1                   # total number of swarms run

# do not edit below this line

n_traj_in_each_swarm = n_sel_clusters * n_sel_frames
#----------------------------------------------------------------------------


for swarm_id in range(total_n_of_swarms):
    # analysing swarms and building tICA and selecting new frames
    print("\tCalculating tICA parameters...")
    for traj_id in range(n_traj_in_each_swarm):
        vmd_cal_parms(vmd_path,psf_path,swarm_id,traj_id)
