# Table of contents:
- [Install Dependencies](#install-dependencies)
  * [OpenMM](#openmm)
  * [Python Libraries](#python-libraries)
  * [VMD](#vmd)
- [Nomenclature](#nomenclature)

- [Job-specific files](#job-specific-files)
  * [./common](#common)
  * [./tcls](#tcls)
- [Workflow](#workflow)
  * [Step 1: Initial structures](#initial-structures)
  * [Step 2: Generate swarm directory structure](#step-2-generate-swarm-directory-structure)
  * [Step 3: Launching a swarm](#step-3-launching-a-swarm)
  * [Step 4: Concatenate swarm subjobs](#step-4-concatenate-swarm-subjobs)
  * [Step 5: Calculate tICA parameters](#step-5-calculate-tica-parameters)
  * [Step 6: Calculate tICA projection and select frames for next swarm](step-6-calculate-tica-projection-and-select-frames-for-next-swarm)
  * [Step 7: Repeat prior steps!](#step-7-repeat-prior-steps)
<!-- toc -->
---
# Install Dependencies

#### OpenMM
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

Once Miniconda is installed, you'll need to create a conda environement for openMM:

```
conda create -n openmm731_cuda101 python=3.7.3
```

(the following instructions are adapted from [Installing OpenMM on Summit](https://github.com/inspiremd/conda-recipes-summit))

Next, activate this environement:
```conda activate openmm731_cuda101```

Add conda-forge and omnia to your channel list and update packages
```
conda config --add channels omnia --add channels conda-forge
# Update to conda-forge versions of packages
conda update --yes --all
```



#### Python Libraries
#### VMD

# Nomenclature

# Job-specific files
#### ./common
#### ./tcls

# Workflow

#### Step 1: Initial structures
#### Step 2: Generate swarm directory structure
#### Step 3: Launching a swarm
#### Step 4: Concatenate swarm subjobs
#### Step 5: Calculate tICA parameters
#### Step 6: Calculate tICA projection and select frames for next swarm
#### Step 7: Repeat prior steps!
---