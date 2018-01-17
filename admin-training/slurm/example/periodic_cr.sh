#!/bin/bash
#SBATCH -J PeriodicCR
#SBATCH --time=00:30:00
#SBATCH --mem-per-cpu=200
#SBATCH --cpus-per-task=1
#SBATCH --open-mode=append
#SBATCH -p requeue
#SBATCH --time-min=00:00:30 # Minimum time to perform the compute of chekpointable cycle + time to dump the information to the shared filesystem

if [[ -e periodic_cr.state ]]; then
    i=$(cat periodic_cr.state)
else
    i=0
fi
while $TRUE; do
    i=$(($i+1))
    echo $i > periodic_cr.state
    sleep 5
done
