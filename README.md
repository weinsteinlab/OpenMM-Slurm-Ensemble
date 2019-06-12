# Table of contents:
- [Install Dependencies](#install-dependencies)
  * [OpenMM](#openmm)
  * [VMD](#vmd)
  * [Python Libraries](#python-libraries)
- [Pre-workflow setup](#pre-workflow-setup)
  * [./common](#common)
  * [./tcls](#tcls)
- [Workflow](#workflow)
  * [Step 1: Initial structures](#step-1-initial-structures)
  * [Step 2: Generate swarm directory structure](#step-2-generate-swarm-directory-structure)
  * [Step 3: Launching a swarm](#step-3-launching-a-swarm)
  * [Step 4: Concatenate swarm subjobs](#step-4-concatenate-swarm-subjobs)
  * [Step 5: Calculate tICA parameters](#step-5-calculate-tica-parameters)
  * [Step 6: Calculate tICA projection and select frames for next swarm](step-6-calculate-tica-projection-and-select-frames-for-next-swarm)
  * [Step 7: Repeat prior steps!](#step-7-repeat-prior-steps)
<!-- toc -->
---
# Install Dependencies

This molecular dynamics (MD) adaptive sampling workflow has several software dependencies: 

*  openMM, 
*  VMD,
*  several python libraries

In this section, we describe how to install these dependencies on Summit. 

### OpenMM
This procedure assumes you have installed miniConda on Summit in a directory that you own. For instructions on how to do this, please see:
[Miniconda on Power9](https://docs.conda.io/en/latest/miniconda.html)

In brief, here are the steps to install Miniconda on Summit. These steps will likely atrophy, but as of 6/10/2019:

```
# ssh onto Summit login node
cd where_you_wish_to_download_Miniconda_installer
wget 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-ppc64le.sh'
chmod 755 ./Miniconda3-latest-Linux-ppc64le.sh
./Miniconda3-latest-Linux-ppc64le.sh

# follow instructions from installer
```

Once Miniconda is installed, you'll need to create a conda environment for openMM:
```
conda create -n openmm740_cuda101 python=3.7.3
```

(the following instructions are adapted from [Installing OpenMM on Summit](https://github.com/inspiremd/conda-recipes-summit))

Activate this environment:
```
conda activate openmm740_cuda101
```

Add conda-forge and omnia to your channel list and update packages
```
conda config --add channels omnia --add channels conda-forge
conda update --yes --all
```

Next, install OpenMM:
```
conda install --yes -c omnia-dev/label/cuda92 openmm
```

**Note:** in the above, cuda92 is referenced, but we need to use cuda10.1.105. In order to do so, we need to rebuild several packages and openMM first. 

Before rebuilding any packages, we'll first need to install a few more packages:
```
conda install numpy swig fftw3f doxygen pymbar
```

To rebuild these packages, you'll need to grab a copy of [this GitHub repository](https://github.com/inspiremd/conda-recipes-summit):
```
cd where_you_want_to_download_the_git_repo
git clone https://github.com/inspiremd/conda-recipes-summit.git
cd conda-recipes-summit/
conda build --numpy 1.13.1 --python 3.6.3 parmed
conda install --use-local parmed
```

**Note:** in the above I reference python 3.6.3--this is because python gets downgraded due to dependency-python compatibility issues.

Finally, it's time to rebuild openMM:

```
module unload cuda
module load cuda/10.1.105
CUDA_VERSION="10.1" CUDA_SHORT_VERSION="101" conda build --numpy 1.15 --python 3.6 openmm
conda install --yes --use-local openmm
```

### VMD
Installation of [VMD](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD) on Summit is trivial (however, you will have to create a free account).

After you have created the account and agreed to the license, download the link to an appropiate directory that you own on Summit. Un-tar the VMD tarball, and follow the installation instructions found in the README file.


### Python Libraries

**Note:** if you already have a conda environement activated, make sure to deactivate it before proceeding.
```
conda deactivate
```

First, create a conda environement for tICA's python dependencies:

**Note:** if you already have a conda environement activated, make sure to deactivate it before proceeding.
```
conda create -n tica_env python=3.7.3
```

Next, activate this environment:
```
conda activate tica_env
```

Once activated, let's install the needed packages and python libraries:
```
conda install numpy matplotlib tqdm h5py scikit-learn
```

That's it--if everything went correctly, all dependencies needed for this workflow should now be installed!

# Pre-workflow setup

**Note:** you can skip the pre-workflow setup if you are just running the test system found in this repository.

The first step in using these tools is to first clone a copy of this respository, in a directory that is appropiate for running swarms of MD simulations ('swarm' is defined in the [this section](#step-1-initial-structures)).
```
cd wherever_you_wish_to_run
git clone git@scu-git.med.cornell.edu:des2037/adaptive-sampling-workflow-tools-for-summit.git
```

Optionally, you can rename the cloned repository to something meaningful for your calculations
```
mv adaptive-sampling-workflow-tools-for-summit my_adaptive_sampling_run
```
Once this is done, go into this directory:
```
cd my_adaptive_sampling_run # or whatever the directory is named at this point
```

**Note: you can skip the rest of this section and go to [Workflow](#workflow) if you are just running the test system found in this repository.**


Next, you'll need to populate/edit files in 2 directories: ./common & ./tcls

### ./common
This directory must contain all of the simulation system-specific files needed to simulate your system with openMM:
*  **ionized.psf**: this protein structure file possesses model structural information (bond connectivity, etc.). Currently, this file **MUST** be named ionized.psf (this restriction will be removed in future modificaions).
*  **hdat_3_1_restart_coor.pdb**: this protein data bank file contains the initial coordinates for your system. The file can be named anything, but must end in .pdb or .coor, and cannot be a binary file.
*  **hdat_3_1_restart_coor.xsc**: this NAMD-generated extended system configuration file describes the system's periodic cell size for the .pdb described above. The file can be named anything, but must end in .xsc.
*  **parameters_all36.prm**: this parameter file contains the CHARMM36 parameters needed to simulate your system. Currently, it **MUST** be named: parameters_all36.prm
*  **all_top.rtf**: this file has a description of all the atom types, masses, and elements used by your system. Currently, it **MUST** be named: all_top.rtf.
*  **input.py**: this python script defines the openMM simulation; it **MUST** be named input.py. Here, the statistical ensemble is selected (e.g. NPT), temperature, and many, many other simulation parameters. The key ones to pay attention to are:
    * steps = 100000: the number of simulation steps per simulation subjob (subjobs are described later), but basically this should be the number of steps that can be run in 2 hours or less.
    * dcdReporter = DCDReporter(dcd_name, 20000): here the last number indicates how often the coordinates are written to the .dcd file; in this example, it's every 20,000 steps.
    * dataReporter = StateDataReporter(log_name, 20000, ...: here, the 20000 indicates how frequenctly the log file is populated with simulation details, such as various energies and simulation progress.
*  **gpu_[0-5].erf**: these template explicit resource files are used by the code in this repository to assign specific node and GPU resources to individual jobs. No need to edit these files.
*  **run_python.sh**: this script is used by other scripts in this workflow. No need to edit.

### ./tcls
This directory contains all of the tcl scripts, run by VMD, to measure pre-defined collective variables (CVs) for the accumulated trajectories. Currently, these tcls scripts/related CVs are very hard-coded. This will hopefully be generalized in upcoming repository updates.


# Workflow

### Step 1: Initial structures
This first step of this workflow is to create a directory with many copies of the initial pdb file. This directory is used in later steps in constructing swarms of MD simulations. A **swarm** is simply a set of independently run MD simulations that may or may not have a common starting conformation. **Note:** duplicating the initial structure is obviously inefficient, but not particularily expensive as the file is small. Furthermore, this allows an MD swarm to be started from many different starting structures if desired.    

To create this directory, open ```populate_initial_structures.sh``` in vim, and edit the following variables:
```
number_of_trajs_per_swarm=18
structure_file='dat_phase2b4.coor' # must be in ./common
```

`number_of_trajs_per_swarm` is the number of MD simulations (hereafter trajectories) per MD swarm.
`structure_file='dat_phase2b4.coor'` is the name of the initial structure (must be `.pdb` or `.coor`, and can't be a binary file). No path is given because this file is assumed to be in `./common` and is enclosed in single quotes.

After editing this file, generate the inital structures directory with the following command:
```
./populate_initial_structures.sh
```

**Note:** this step is so lightweight that it is currently just run on the login node (i.e. not submitted to the job queue).




### Step 2: Generate swarm directory structure
### Step 3: Launching a swarm
### Step 4: Concatenate swarm subjobs
### Step 5: Calculate tICA parameters
### Step 6: Calculate tICA projection and select frames for next swarm
### Step 7: Repeat steps 2-6!
---