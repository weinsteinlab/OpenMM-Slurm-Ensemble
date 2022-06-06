
# run readInputFiles.py
exec(open("./readInputFiles.py").read())


# System Configuration
nonbondedMethod = PME
nonbondedCutoff = 12*angstroms
switchDistance=10*angstroms

ewaldErrorTolerance = 0.0005
constraints = HBonds
rigidWater = True
constraintTolerance = 0.000001


# Integration Options
dt = 0.004*picoseconds
temperature = 310.15*kelvin
friction = 1.0/picosecond


# Simulation Options
steps = 80000
equilibrationSteps = 0
dcdReporter = DCDReporter(dcd_name, 20000)

dataReporter = StateDataReporter(log_name, 20000, totalSteps=steps, step=True, time=True, speed=True, progress=True, elapsedTime=True, remainingTime=True, potentialEnergy=True, kineticEnergy=True, totalEnergy=True, temperature=True, volume=True, density=True, separator=',')


# Prepare the Simulation
print('Building system...')
topology = psf.topology
positions = pdb.positions
system = psf.createSystem(params, nonbondedMethod=PME, nonbondedCutoff=nonbondedCutoff, constraints=constraints, rigidWater=rigidWater, ewaldErrorTolerance=ewaldErrorTolerance, switchDistance=switchDistance, hydrogenMass=4*amu)
system.addForce(MonteCarloMembraneBarostat(1.01325*bar, 0*bar*nanometer, 310*kelvin, MonteCarloMembraneBarostat.XYIsotropic, MonteCarloMembraneBarostat.ZFree))

integrator = LangevinMiddleIntegrator(temperature, friction, dt)
integrator.setConstraintTolerance(constraintTolerance)
simulation = Simulation(topology, system, integrator, platform, platformProperties)
simulation.context.setPositions(positions)


# Set velocity and loadCheckpoint if available
simulation.context.setVelocitiesToTemperature(temperature)
simulation.currentStep = 0

if int(subjob_number) > 0: 
    simulation.loadState(priorRestart)
    setupLog = open('%s_setupLog.txt' % base_name, 'a')
    setupLog.write("Restart file: %s" % priorRestart )
    setupLog.close()
    

# Simulate
print('Simulating...')
simulation.reporters.append(dcdReporter)
simulation.reporters.append(dataReporter)
simulation.step(steps)
simulation.saveState('final_state_file.xml')

positions = simulation.context.getState(getPositions=True).getPositions()
PDBFile.writeFile(simulation.topology, positions, open(final_pdb_name, 'w'))

os.system('cp final_state_file.xml %s_statefile.xml' %base_name)
print("FINISHED")
