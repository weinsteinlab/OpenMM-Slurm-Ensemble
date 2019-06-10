import os,sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from matplotlib import rcParams
rcParams.update({'figure.autolayout': True})
rcParams['axes.linewidth'] = 2
rcParams.update({'font.size': 16})

from tica import *
from sklearn.cluster import KMeans as KMeans

def vmd_cal_parms(vmd_path,psf_path,swarm_id,traj_id):
    if os.path.exists('analysis/tica_parameters/swarm%s_traj%s.npy' %(str(swarm_id).zfill(4),str(traj_id).zfill(4))): return None 
    tica_parameter_list = ['na2_na1.txt','na2_e428.txt','na2_d421.txt','na2_d79.txt','na2_water_coord.txt',\
'r60_y335.txt','r60_e446.txt','r60_e428.txt','r60_d436.txt','y335_e428.txt','d436_r445.txt','e428_r445.txt']
    text = """%s -dispdev none %s swarms_concatenated_temp/%s/%s.trr >> log_vmd.log <<EOF
play tcls/tk_na2_na1.tcl
play tcls/tk_na2_e428.tcl
play tcls/tk_na2_d421.tcl
play tcls/tk_na2_d79.tcl
play tcls/tk_na2_water_coord.tcl
play tcls/tk_r60_y335.tcl
play tcls/tk_r60_e446.tcl
play tcls/tk_r60_e428.tcl
play tcls/tk_r60_d436.tcl
play tcls/tk_y335_e428.tcl
play tcls/tk_d436_r445.tcl
play tcls/tk_e428_r445.tcl
quit
EOF
""" %(vmd_path,psf_path,str(swarm_id).zfill(4),str(traj_id).zfill(4))
    f = open('vmd_temp.sh','w')
    f.writelines(text)
    f.close()
    os.system('bash vmd_temp.sh')
    if not os.path.exists('analysis'): os.system('mkdir analysis')
    if not os.path.exists('analysis/tica_parameters'): os.system('mkdir analysis/tica_parameters')
    n_frames = len(np.loadtxt(tica_parameter_list[0]))
    data = np.empty((n_frames,len(tica_parameter_list)))
    for i in range(len(tica_parameter_list)): 
        data[:,i] = np.loadtxt(tica_parameter_list[i])
        os.system('rm %s' %(tica_parameter_list[i]))
    np.save('analysis/tica_parameters/swarm%s_traj%s.npy' %(str(swarm_id).zfill(4),str(traj_id).zfill(4)),data)



def cal_tica(swarm_id,tica_lag_time,start_swarm_id,end_swarm_id,start_traj_id,end_traj_id):
    print("\tObtaining tICA object...")
    if not os.path.exists('analysis/tica_objects'): os.system('mkdir analysis/tica_objects')
    tica_name = 'analysis/tica_swarm%s_to_swarm%s_traj%s_to_traj%s.npy' %(str(start_swarm_id).zfill(4),str(end_swarm_id).zfill(4),str(start_traj_id).zfill(4),str(end_traj_id).zfill(4))
    tica = tICA(n_components=None, lag_time=int(tica_lag_time))
    dataset = []
    for i in range(start_swarm_id,end_swarm_id):
        for j in range(start_traj_id,end_traj_id):
            dataset.append(np.load('analysis/tica_parameters/swarm%s_traj%s.npy' %(str(i).zfill(4),str(j).zfill(4))))
    tica.fit(dataset)
    print("\tfirst 5 tICA eigenvalues:", tica.eigenvalues_[0:5])
    tica_dict = {}
    tica_dict['covariance'] = tica.covariance_
    tica_dict['time_lagged_covariance'] = tica.offset_correlation_
    tica_dict['eigenvalues'] = tica.eigenvalues_
    tica_dict['eigenvectors'] = tica.eigenvectors_
    tica_dict['lag_time'] = tica.lag_time
    np.save('analysis/tica_objects/tica_swarm%s.npy' %str(swarm_id).zfill(4), tica_dict)
    print("\tSaved tICA object: %s" %tica_name)
    return tica, tica_name

def project_on_tica(tica,tica_name, file_tica_projection_name, start_swarm_id,end_swarm_id,start_traj_id,end_traj_id):
    if not os.path.exists('analysis/tica_projections') : os.system('mkdir analysis/tica_projections')
    dataset = []
    for i in range(start_swarm_id,end_swarm_id):
        for j in range(start_traj_id,end_traj_id):
            d = np.load('analysis/tica_parameters/swarm%s_traj%s.npy' %(str(i).zfill(4),str(j).zfill(4)))
            dataset.append(np.dot(d,tica.eigenvectors_))
    np.save('analysis/tica_projections/%s' %file_tica_projection_name, dataset)
    print("\tSaved tICA projections at: 'analysis/tica_projections/%s' " %file_tica_projection_name)
    return dataset

def plot_tica_landscape(file_tica_projection_name, file_tica_fig_name):
    if not os.path.exists('analysis/tica_projections') : os.system('mkdir analysis/tica_projections')
    ev0, ev1 = [], []
    projs = np.load('analysis/tica_projections/%s' %file_tica_projection_name)
    for i in projs:
        ev0.extend(i[:,0]); ev1.extend(i[:,1])
    ev0, ev1 = np.array(ev0), np.array(ev1)
    plt.figure(figsize=(12,8))
    plt.hist2d(ev0,ev1,bins=100,norm=LogNorm())
    plt.savefig('analysis/tica_projections/%s' %file_tica_fig_name)
    print("\tSaved tica landscape at: 'analysis/tica_projections/%s' " %file_tica_fig_name)


def cluster_on_tica(n_clusters,projected_data,swarm_id,n_sel_clusters,n_sel_frames,plot_sel_frames=True):
    """
    inputs:
    n_clusters: number of clusters
    projected_data: a list of projected data on tICA in the form: [(# of frames, # of tICs),..]  ; len(projected_data) = number of trajectories
    n_sel_clusters: number of clusters with lowest populations where frames will be extracted
    n_sel_frames: number of frames to be extracted from each `n_sel_clusters`
    """
    if not os.path.exists('analysis/clustering/'): os.system('mkdir analysis/clustering/')
    cluster = KMeans(n_clusters=n_clusters,n_jobs=1,verbose=0, max_iter=100, tol=0.0001,)
    dataset = []

#    # using cluster from MSMbuilder
#    for i in projected_data: dataset.append(i[:,0:2])		# using first 2 tICs for clustering
#    cluster.fit(dataset)
#    print("\tINFO: total number of trajectories: %d" %len(dataset))
#    np.save('analysis/clustering/swarm%d_assigns.npy' %swarm_id,cluster.labels_)
#    labels_ = cluster.labels_

    # using cluster from SKlearn
    traj_lens = []
    for i in projected_data: dataset.extend(i[:,0:2]) ; traj_lens.append(len(i))
    print("\tINFO: total number of datapoints: %d" %len(dataset))
    print("\tINFO: total number of trajectories: %d" %len(traj_lens))
    cluster.fit(dataset)
    labels_ = np.split(cluster.labels_,np.cumsum(traj_lens))[0:-1]
    np.save('analysis/clustering/swarm%s_assigns.npy' %str(swarm_id).zfill(4),labels_)
    dataset = np.split(dataset,np.cumsum(traj_lens))[0:-1]
    
    np.savetxt('analysis/clustering/swarm%s_gens.txt' %str(swarm_id).zfill(4),np.array(cluster.cluster_centers_))
    # selecting frame ids
    all_frames = []
    for i in labels_: all_frames.extend(i)
    all_frames = np.array(all_frames)
    cluster_populations = np.empty(cluster.n_clusters, dtype=int)
    for i in range(cluster.n_clusters):
        cluster_populations[i] = len(np.where(all_frames == i)[0])
    print("\tINFO: cluster populations:", cluster_populations)
    sort_clusters = np.argsort(cluster_populations)
    sel_trajs = []
    sel_frames = []
    for i in range(n_sel_clusters):
        index = np.array([sort_clusters[i] in ii for ii in labels_])
        cluster_index = np.where(index == True)[0]
        for j in range(n_sel_frames):
            ind_traj = np.random.choice(cluster_index,1)[0]
            _frames = (labels_[ind_traj] == sort_clusters[i])
            ind_frame = np.random.choice(np.where(_frames==True)[0],1)
            sel_trajs.append(ind_traj)
            sel_frames.append(ind_frame)

    if plot_sel_frames:
        plt.figure(figsize=(10,7))
        ev0, ev1 = [], []
        for i in dataset: ev0.extend(i[:,0]) ; ev1.extend(i[:,1])
        plt.hist2d(ev0,ev1,bins=100,norm=LogNorm())
        for traj,frame in zip(sel_trajs,sel_frames):
            point_x, point_y = dataset[traj][frame][0]
            plt.plot(point_x,point_y,'*',markersize=16,color='r')
        plt.savefig('analysis/clustering/img_sel_frames_swarm_%s.png' %str(swarm_id).zfill(4))
        print("\tINFO: saved selected frames location on tICA landscape at: analysis/clustering/img_sel_frames_swarm_%s.png" %str(swarm_id).zfill(4))
        plt.close()
    return sel_trajs, sel_frames
 
def save_sel_frames_mdtraj(sel_trajs,sel_frames,pdb_path,swarm_id,n_traj_in_each_swarm=20):
    if not os.path.exists('./selected_frames/sel_frames_swarm_%s/' %str(swarm_id).zfill(4)): os.system('mkdir -p ./selected_frames/sel_frames_swarm_%s/' %str(swarm_id).zfill(4))
    ref = md.load(pdb_path)
    for ii,traj,frame in zip(range(len(sel_trajs)),sel_trajs,sel_frames):
        sel_swarm_id = traj / n_traj_in_each_swarm
        sel_traj_id = traj % n_traj_in_each_swarm 
        print(traj, sel_swarm_id, sel_traj_id, frame)
        t = md.load('swarms_concatenated_temp/%s/%s.trr' %(str(sel_swarm_id).zfill(4),str(int(sel_traj_id).zfill(4))),top=ref)
        t.xyz = t.xyz[frame,:,:]
        t.save_pdb('./selected_frames/sel_frames_swarm_%s/%s_swarm%s_traj%s_frame%s.pdb' %(str(swarm_id).zfill(4),str(ii).zfill(4),str(sel_swarm_id).zfill(4),str(traj).zfill(4),str(frame).zfill(4)))
        t.save_pdb('./selected_frames/sel_frames_swarm_%s/%s.pdb' %(str(swarm_id).zfill(4),str(ii).zfill(4)))
    print("\tINFO: Saved pdb files for selected frames at: ./selected_frames/sel_frames_swarm_%s" %(str(swarm_id).zfill(4)))

def save_sel_frames(sel_trajs,sel_frames,vmd_path,psf_path,swarm_id,n_traj_in_each_swarm=20):
    if os.path.exists('./selected_frames/sel_frames_swarm_%s' %str(swarm_id).zfill(4)): return None
    print("\tINFO: extracting new frames...")
    if not os.path.exists('./selected_frames/sel_frames_swarm_%s/' %str(swarm_id).zfill(4)): os.system('mkdir -p ./selected_frames/sel_frames_swarm_%s/' %str(swarm_id).zfill(4))
    for ii,traj,frame in zip(range(len(sel_trajs)),sel_trajs,sel_frames):
        sel_swarm_id = traj / n_traj_in_each_swarm
        sel_traj_id = traj % n_traj_in_each_swarm
        os.system(''' %s -dispdev none %s swarms_concatenated_temp/%s/%s.trr >> log_vmd.log <<EOF
animate write pdb ./selected_frames/sel_frames_swarm_%s/%s_swarm%s_traj%s_frame%s.pdb beg %d end %d
quit
EOF
''' %(vmd_path,psf_path,str(int(sel_swarm_id)).zfill(4),str(int(sel_traj_id)).zfill(4), str(swarm_id).zfill(4),str(ii).zfill(4),str(int(sel_swarm_id)).zfill(4),str(int(traj)).zfill(4),str(int(frame)).zfill(4),frame,frame))
    print("\tINFO: Saved pdb files for selected frames at: ./selected_frames/sel_frames_swarm_%s" %(str(swarm_id).zfill(4)))

