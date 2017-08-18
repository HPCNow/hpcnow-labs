#!/bin/bash
#SBATCH -J ScalabilityTests
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=2G
ml intel/2017a 
######################################################################################
cd $SHM_DIR
srun $HOME/snow-labs/user-training/examples/single_task_tuning/openmp_mm > output.txt
echo "$SLURM_CPUS_PER_TASK : $(cat output.txt)" >> $HOME/snow-labs/user-training/OUT/benchmark-results.txt
