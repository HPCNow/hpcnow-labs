#!/bin/bash
#SBATCH -J ArrayJob
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --array=1-1000
ml Application
srun array_binary "${SLURM_ARRAY_TASK_ID}"
