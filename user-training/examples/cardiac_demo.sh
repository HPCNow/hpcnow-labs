#!/bin/bash
# This script is part of HPCNow! Labs training documentation.
# Visit the following URL for more information: https://github.com/hpcnow/hpcnow-labs
# Copyright (C) 2017 Jordi Blasco
# Permission is granted to copy, distribute and/or modify this document
# under the terms of the GNU Free Documentation License, Version 1.3
# or any later version published by the Free Software Foundation;
# with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
# A copy of the license is included in the section entitled "GNU
# Free Documentation License".
#SBATCH -J Cardiac_demo_test
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=6144
# Load the development environment module
ml intel/2017a
# Transfer required input files to the shared (temporary) file system 
cp $HOME/hpcnow-labs/user-training/examples/Cardiac_demo/mesh_mid* $SCRATCH_DIR/
cp $HOME/hpcnow-labs/user-training/examples/Cardiac_demo/setup_mid.txt $SCRATCH_DIR/
cd $SCRATCH_DIR
# Run the application
srun $HOME/hpcnow-labs/user-training/examples/Cardiac_demo/build/heart_demo -m ./mesh_mid -s ./setup_mid.txt -t 50 | tee output.txt
echo "$SLURM_NTASKS x $SLURM_CPUS_PER_TASK : $(grep 'wall time:' output.txt)" >> $HOME/hpcnow-labs/user-training/OUT/benchmark-results.txt
mkdir -p $HOME/hpcnow-labs/user-training/OUT
cp -pr $SCRATCH_DIR $HOME/hpcnow-labs/user-training/OUT/
