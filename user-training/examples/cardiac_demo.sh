#!/bin/bash
#SBATCH -J Cardiac_demo_test
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=6144
# Load the development environment module
ml intel/2017a
# Transfer required input files to the shared (temporary) file system 
cp $HOME/snow-labs/user-training/examples/Cardiac_demo/mesh_mid* $SCRATCH_DIR/
cp $HOME/snow-labs/user-training/examples/Cardiac_demo/setup_mid.txt $SCRATCH_DIR/
cd $SCRATCH_DIR
# Run the application
srun $HOME/snow-labs/user-training/examples/Cardiac_demo/build/heart_demo -m ./mesh_mid -s ./setup_mid.txt -t 50 | tee output.txt
echo "$SLURM_NTASKS x $SLURM_CPUS_PER_TASK : $(grep 'wall time:' output.txt)" >> $HOME/snow-labs/user-training/OUT/benchmark-results.txt
mkdir -p $HOME/snow-labs/user-training/OUT
cp -pr $SCRATCH_DIR $HOME/snow-labs/user-training/OUT/
