#!/bin/bash
#SBATCH -J OpenMPJob
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=8
ml Application
srun openmp_binary
