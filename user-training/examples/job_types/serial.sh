#!/bin/bash
#SBATCH -J SerialJob
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=8G
ml Application
srun serial_binary
