#!/bin/bash
#SBATCH -J ScalabilityTests
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=2G
ml intel/2017a 
######################################################################################
cp $HOME/snow-labs/user-training/examples/Cardiac_demo/mesh_mid* $SCRATCH_DIR/
cp $HOME/snow-labs/user-training/examples/Cardiac_demo/setup_mid.txt $SCRATCH_DIR/
cd $SCRATCH_DIR
srun $HOME/snow-labs/user-training/examples/Cardiac_demo/build_non-instrumented/heart_demo -m ./mesh_mid -s ./setup_mid.txt -t 50
mkdir -p $HOME/snow-labs/user-training/OUT/
echo "$SLURM_NTASKS x $SLURM_CPUS_PER_TASK : $(grep 'wall time:' output.txt)" >> $HOME/snow-labs/user-training/OUT/benchmark-results.txt
