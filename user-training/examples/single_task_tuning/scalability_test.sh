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
#SBATCH -J ScalabilityTests
#SBATCH --time=00:10:00
#SBATCH --mem=16G
ml intel/2017a
######################################################################################
cd $SHM_DIR
srun $HOME/hpcnow-labs/user-training/examples/single_task_tuning/openmp_mm > output.txt
mkdir -p $HOME/hpcnow-labs/user-training/OUT
echo "$SLURM_CPUS_PER_TASK : $(cat output.txt)" >> $HOME/hpcnow-labs/user-training/OUT/benchmark-results.txt
