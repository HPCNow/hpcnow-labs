#!/bin/bash
#SBATCH -J GPUJob
#SBATCH --time=01:00:00
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --mem-per-cpu=8G
#SBATCH --gres=gpu:2
ml Application
srun binary_cuda_mpi
