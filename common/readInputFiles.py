# This script was generated by OpenMM-Setup on 2019-02-15.
import os, sys, glob, datetime, socket
from simtk.openmm import *
from simtk.openmm.app import *
from simtk.unit import *
from sys import stdout

def read_params(filename):
    extlist = ['rtf', 'prm', 'str']

    parFiles = ()
    for line in open(filename, 'r'):
        if '!' in line: line = line.split('!')[0]
        parfile = line.strip()
        if len(parfile) != 0:
            ext = parfile.lower().split('.')[-1]
            if not ext in extlist: continue
            parFiles += ( parfile, )

    params = CharmmParameterSet( *parFiles )
    return params

# command_line variables
current_directory = os.path.basename(os.getcwd())

swarm_number  = current_directory.split('_')[0][-4:]
traj_number   = current_directory.split('_')[1][-4:]
subjob_number = sys.argv[1]
gpu_number = sys.argv[2]

base_name="./swarm%s_traj%s_subjob%s" %(str(swarm_number).zfill(4), str(traj_number).zfill(4),str(subjob_number).zfill(4))

# Output Files
dcd_name       = "%s.dcd" %(base_name)
log_name       = "%s.log" %(base_name)
final_pdb_name = "%s.pdb" %(base_name)

# Input Files
mass_files = str(','.join(glob.glob('*.rtf')))
parameter_files = str(','.join(glob.glob('*.prm')))

psf = CharmmPsfFile(str(''.join(glob.glob('*.psf'))))
pdb = PDBFile(sorted(glob.glob('*.pdb'))[0])
params = read_params('./toppar.str')

if (int(subjob_number) > 0):
  #priorRestart = sorted(glob.glob('*.xml'))[-1]
  prior_subjob = int(subjob_number) - 1
  priorRestart = "./swarm%s_traj%s_subjob%s_statefile.xml" %(str(swarm_number).zfill(4), str(traj_number).zfill(4),str(prior_subjob).zfill(4))

# Compute the box dimensions from the coordinates and set the box lengths (only
# orthorhombic boxes are currently supported in OpenMM)
xsc_file_name = sorted(glob.glob('*.xsc'))[0]
xsc_file = open(xsc_file_name, 'r')
xsc_last_line = xsc_file.read().splitlines()[-1].split(' ')
xsc_file.close()


# get date/time
now = datetime.datetime.now()
dateAndTimeNow = now.strftime("%d/%m/%Y %H:%M:%S")


# get openMM version info
calculationVersion = Platform.getOpenMMVersion()
calculationGit     = version.git_revision

# get hostname
print(socket.gethostname())
thisServer=socket.gethostname()

# Write list of input files to log file
setupLog = open('%s_setupLog.txt' % base_name, 'w')
setupLog.write("OpenMM Version: %s\n" % calculationVersion)
setupLog.write("Git Revision: %s\n\n" % calculationGit)
setupLog.write("This calculation was started: %s\n\n" % dateAndTimeNow)
setupLog.write("Compute Node: %s\n\n" % thisServer)

setupLog.write("These are the files that were read into this subjob.\n")
setupLog.write("Note: if checkpoint file is read, values in some of these files will not used.\n\n")
setupLog.write("psf file: %s\n" % str(''.join(glob.glob('*.psf'))))
setupLog.write("pdb file: %s\n" % sorted(glob.glob('*.pdb'))[0])
setupLog.write("xsc file: %s\n\n" % sorted(glob.glob('*.xsc'))[0])
setupLog.write("Mass Files: %s\n" % mass_files)
setupLog.write("Parameter Files: %s\n\n" % parameter_files)

restartUsed="TRUE" if (int(subjob_number) > 0) else "FALSE" 
setupLog.write("Restart file used? %s\n" % restartUsed)

setupLog.close()


# Divide by 10 because NAMD xsc is in angstroms, whereas nanometers is the default in openMM
x_PBC_vector_length = float(xsc_last_line[1])/10
y_PBC_vector_length = float(xsc_last_line[5])/10
z_PBC_vector_length = float(xsc_last_line[9])/10

psf.setBox(x_PBC_vector_length, y_PBC_vector_length, z_PBC_vector_length)


# Infrastructure description
platform = Platform.getPlatformByName('CUDA')
platformProperties = {'DeviceIndex': str(gpu_number), 'Precision': 'mixed'}
