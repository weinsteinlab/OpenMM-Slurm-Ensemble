import os,sys
import numpy as np
from utils import vmd_cal_parms, cal_tica,   project_on_tica, plot_tica_landscape,   cluster_on_tica, save_sel_frames
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
total_n_of_swarms = 0

# do not edit below this line

n_traj_in_each_swarm = n_sel_clusters * n_sel_frames
#----------------------------------------------------------------------------

for swarm_id in range(total_n_of_swarms):
    print("\tDone with tICA paramter calculations")
    start_swarm_id, end_swarm_id = 0, swarm_id + 1
    start_traj_id, end_traj_id = 0, n_traj_in_each_swarm
    tica, tica_name = cal_tica(swarm_id,tica_lag_time, start_swarm_id, end_swarm_id, start_traj_id, end_traj_id)
    file_tica_projection_name = 'on_tica_swarm%s.npy' %str(swarm_id).zfill(4)
    project_on_tica(tica, tica_name, file_tica_projection_name, start_swarm_id, end_swarm_id, start_traj_id, end_traj_id)
    file_tica_fig_name = 'img_tica_landscape_swarm%s.png' %str(swarm_id).zfill(4)
    plot_tica_landscape(file_tica_projection_name, file_tica_fig_name)
    projected_data_all = np.load('analysis/tica_projections/%s' %file_tica_projection_name)
    sel_trajs, sel_frames = cluster_on_tica(n_clusters,projected_data_all,swarm_id,n_sel_clusters,n_sel_frames,plot_sel_frames=True)
    save_sel_frames(sel_trajs, sel_frames, vmd_path, psf_path, swarm_id, n_traj_in_each_swarm=n_traj_in_each_swarm)

