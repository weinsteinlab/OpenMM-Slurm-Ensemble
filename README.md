# Table of contents:
- [Setup Environment](#setup-enviornment)
- [Pre-workflow setup](#pre-workflow-setup)
- [OpenMM Ensemble Workflow](#openmm-ensemble-workflow)
  * [Step 1: Generate swarm directory structure](#step-1-generate-swarm-directory-structure)
  * [Step 2: Launching a swarm](#step-2-launching-a-swarm)
  * [Step 3: Concatenate swarm subjobs](#step-3-concatenate-swarm-subjobs)
  * [Step 4: Repeat steps 1-3!](#step-4-repeat-steps-1-3)
<!-- toc -->
---
# Setup Environment

This molecular dynamics (MD) adaptive sampling workflow has several software dependencies: 

*  openMM, 
*  VMD,
*  several python libraries

This software is already installed for the Weinstein lab. In this section, we describe how to setup your environment to use these installations.

Add the following to your `~.bashrc`

```
export PATH=$PATH:/athena/hwlab/scratch/lab_data/software/vmd/vmd-1.9.3_athena/install_bin
export PATH=$PATH:/athena/hwlab/scratch/lab_data/software/vmd/vmd-1.9.3_athena/plugins/LINUXAMD64/bin/catdcd5.1

#>>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/athena/hwlab/scratch/lab_data/software/lab_anaconda/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/athena/hwlab/scratch/lab_data/software/lab_anaconda/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/athena/hwlab/scratch/lab_data/software/lab_anaconda/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/athena/hwlab/scratch/lab_data/software/lab_anaconda/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<</vmd

```
**Note:** Make SURE there are **NO** other references to (ana)conda or VMD in your `~/.bashrc` or you may get very unpredictable results.

That's it--if everything went correctly, all dependencies needed for this workflow should now be available!

# Pre-workflow setup

**Note:** you can skip the pre-workflow setup if you are just running the test system found in this repository.

The first step in using these tools is to first clone a copy of this repository, in a directory that is appropriate for running swarms of MD simulations ('swarm' is defined in the [this section](#step-1-initial-structures)).
```
cd wherever_you_wish_to_run
git@scu-git.med.cornell.edu:des2037/summit-openmm-ensemble.git
```

Optionally, you can rename the cloned repository to something meaningful for your calculations
```
mv adaptive-sampling-workflow-tools-for-summit my_adaptive_sampling_run
```
Once this is done, go into this directory:
```
cd my_adaptive_sampling_run # or whatever the directory is named at this point
```

**Note: directory is hereafter referred to as the parent directory**


Next, you'll need to populate/edit files in the directory `./inputs`

**Note:** You'll see there is another directory called `./common`: do **NOT** edit anything in this directory! It contains scripts that facilitate job management and should not be edited by the user.

`./inputs` should contain a separate subdirectory for each unique system you wish to run. These subdirectories MUST have 4-zero-padded, zero-indexed names (e.g., `0000`, `0001`, `0002`, etc.). Deviating from this nomenclature WILL break the scripts.

Each subdirectory must contain all of the simulation system-specific files needed to simulate your system with openMM:
*  **ionized.psf**: this protein structure file possesses model structural information (bond connectivity, etc.). The file can be named anything, but must end in .psf, and cannot be a binary file.
*  **hdat_3_1_restart_coor.pdb**: this protein data bank file contains the initial coordinates for your system. The file can be named anything, but must end in .pdb, and cannot be a binary file.
*  **hdat_3_1_restart_coor.xsc**: this NAMD-generated extended system configuration file describes the system's periodic cell size for the .pdb described above. The file can be named anything, but must end in .xsc.
*  **parameters_all36.prm**: this parameter file contains the CHARMM36 parameters needed to simulate your system. Any number of parameters files can be used, and these file can be named anything, but they must end in .prm.
*  **all_masses.rtf**: this file has a description of all the atom types, masses, and elements used by your system. Any number of mass files can be used, and these file can be named anything, but they must end in .rtf.
*  **input.py**: this python script defines the openMM simulation; it **MUST** be named input.py. Here, the statistical ensemble is selected (e.g. NPT), temperature, and many, many other simulation parameters. The key ones to pay attention to are:
    * steps = 100000: the number of simulation steps per simulation subjob (subjobs are described later), but basically this should be the number of steps that can be run in 2 hours or less.
    * dcdReporter = DCDReporter(dcd_name, 20000): here the last number indicates how often the coordinates are written to the .dcd file; in this example, it's every 20,000 steps.
    * dataReporter = StateDataReporter(log_name, 20000, ...: here, the 20000 indicates how frequently the log file is populated with simulation details, such as various energies and simulation progress.
*  **numberOfReplicas.txt**: this file contains to number of replicas to run for this system. MUST be a multiple of 6.

**Note:** make sure you have benchmarked each different system and have adjusted its individual `steps=` parameter accordingly. This workflow supports running an arbitrarily high number of systems (up to 9,999) with no restrictions on size differences. However, this functionality relies on adjusting each systems `steps=` to what can run in 2 hours. 

**Note:** Until experienced with Summit's performance for a given set of systems, I recommend only requesting 80% of the number of steps that can be performed in 2 hours. This way, there is little risk of any of the systems running out of time, creating a mess to clean up.

**VERY IMPORTANT:** `input.py` only contains ensemble-related information. All descriptions of input files are automatically understood by what is present in each subdirectory. Do NOT describe input files in this file, or the scripts will break.

Finally, if you only have 1 system to run (with many replicas), just create 1 subdirectory in `inputs`.


# OpenMM Ensemble Workflow

The steps for the workflow described below must be currently manually run. This is intentional, so as not to complicate integration with other workflow applications. Furthermore, each step below has been designed to represent complete modules/pieces of the workflow, and should not be fractured without some discussion.


---
### Step 1: Generate swarm directory structure
After populating `./inputs` your  step is to generate the directory structure for a given swarm, and all of the subdirectories for the independent trajectories that make up this swarm. 
Open ```setup_individual_swarm.sh``` in vim, and edit the following variables:

```
swarm_number=0
number_of_trajs_per_swarm=24
```

`swarm_number=0` is the swarm number you wish to run; it is zero indexed.
`number_of_trajs_per_swarm=24` is the number of MD trajectories per MD swarm. MUST be a multiple of 6

After editing this file, generate the initial structures directory with the following command:
```
./setup_individual_swarm.sh
```

**Note:** this step is so lightweight that it is currently just run on the login node (i.e. not submitted to the job queue).

This will create the directory `raw_swarms` in your repository's parent directory. In `./raw_swarms`, you'll see the directory `swarm[0-9][0-9][0-9][0-9]`, with the specific number depending on what you set `swarm_number` equal to.

Inside of `swarm[0-9][0-9][0-9][0-9]`, you'll find:
*  swarm0000_traj0000/
*  swarm0000_traj0001/
*  ...
*  swarm0000_traj[n] # where n is `number_of_trajs_per_swarm` zero padded to a width of 4.

These directories will hold all of the files related to running a given swarm's trajectory. 

---

### Step 2: Launching a swarm

To run all of the trajectories that make up the MD swarm, open `launch_swarm.sh` in vim, and edit the following variables:

```
swarmNumber=0
numberOfTrajsPerSwarm=24
firstSubjob=0
lastSubjob=3
jobName="your_job_name" # no spaces
```

The first 2 variables have already been described and must be consistent with whatever was set in `setup_individual_swarm.sh`.

The next 2 variables have to deal with trajectory subjobs. Because Summit has a maximum job runtime of 2 hours, a single trajectory must be run over many subjobs to achieve the needed desired simulation time. The number of subjobs should equal: (total_simulation_time / simulation_time_per_2_hours). **Note: Summit only allows 100 jobs to be submitted per user, so the number of subjobs must be <= 100**

`firstSubjob`: is the number of the first subjob, zero indexed. It should be zero, unless a swarm run crashes and needs to be restarted from a given subjob.
`lastSubjob`: this is `n - number_of_subjobs_you_wish_to_run`
`jobName`: what you wish to name the job (this will be publically visible in the job scheduler)

Finally, submit the MD swarm to the job scheduler with the following command:

```
./launch_swarm.sh
```

This command submits subjob # `first_subjob` to run first (for all of the trajectories within this swarm), with subsequent subjobs dependent on the successful completion of prior subjobs runs. 

The status of the MD swarm can be checked with the following command:

```
bjobs
```

---

### Step 3: Concatenate swarm subjobs

Needs to be re-written to support multiple systems! Work-in-progress!
---


### Step 4: Repeat steps 1-3!

To start the next MD swarm, simply go back to [Step 2](#step-1-generate-swarm-directory-structure) and increment the swarm number (in this example case, the next swarm number is 1).

---
