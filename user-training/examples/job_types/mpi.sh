#!/bin/bash
#SBATCH -J MPIJob
#SBATCH --time=01:00:00
#SBATCH --ntasks=2
#SBATCH --mem-per-cpu=8G
ml supermagic/20170824-foss-2018a
srun supermagic -a -n 1 -m 8M
