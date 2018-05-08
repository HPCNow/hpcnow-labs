#!/bin/bash
#SBATCH -J MPIJob
#SBATCH --time=01:00:00
#SBATCH --ntasks=2
#SBATCH --mem-per-cpu=8G
ml Application
srun mpi_binary
