#!/bin/bash
#SBATCH -J HybridJob
#SBATCH --time=01:00:00
#SBATCH --ntasks=4
#SBATCH --mem-per-cpu=8G 
#SBATCH --cpus-per-task=8
ml Application
srun hybrid_binary
