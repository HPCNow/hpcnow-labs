# Hands-On 04: Prolog and Epilog
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on session, you will be able to setup a custom prolog and epilog per job, task and srun.

Slurm supports a multitude of prolog and epilog programs. Note that for security reasons, these programs do not have a search path set. Either specify fully qualified path names in the program or set the "PATH" environment variable. The first table below identifies what prologs and epilogs are available for job allocations as well as where and when they run.



*Estimated time: 30 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in the hands-on session 01
* Previous hands-on completed


## Prolog
Create three shell scripts with execution permissions:
* /etc/slurm/prolog/job.sh
* /etc/slurm/prolog/task.sh
* /etc/slurm/prolog/srun.sh

### Setting Temporary IO Folders 
Setup a job prolog (/etc/slurm/prolog/job.sh) to create temporary IO folders on a per job basis

```
#!/bin/bash
# Create temporary directories for the job
for DIRECTORY in /scratch/jobs/$SLURM_JOB_USER /dev/shm/jobs/$SLURM_JOB_USER /tmp/jobs/$SLURM_JOB_USER
do
if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    chown $SLURM_JOB_USER $DIRECTORY
    chmod 700 $DIRECTORY
fi
TDIRECTORY=$DIRECTORY/$SLURM_JOBID

if [ ! -d "$TDIRECTORY" ]; then
    mkdir -p $TDIRECTORY
    chown $SLURM_JOB_USER $TDIRECTORY
    chmod 700 $TDIRECTORY
fi 
done
```

### Exposing new variables and modifying the user environment

Create a task prolog to expose new variables and modify the user environment (/etc/slurm/prolog/task.sh)

```
#!/bin/bash

# Exposing the environment variables pointing to the temporary folders
echo "export SHM_DIR=/dev/shm/jobs/$USER/$SLURM_JOBID"
echo "export TMP_DIR=/tmp/jobs/$USER/$SLURM_JOBID"
echo "export SCRATCH_DIR=/scratch/jobs/$USER/$SLURM_JOBID"

# Define a timeout for idle interactive job sessions
echo "export TMOUT=300"

# Exporting a default value of OMP_NUM_THREADS for those jobs 
# requesting multiple CPUs per task.
if [ $SLURM_CPUS_PER_TASK -ge 1 ]; then
    echo "export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK"
fi
```

### Job auditing (OGRT)
Create a srun prolog to audit those applications executed with srun launcher (/etc/slurm/prolog/srun.sh).
More information on this is available here: https://github.com/georg-rath/ogrt

```
echo "export OGRT_ACTIVE=1"
echo "export OGRT_SILENT=1"
if [ -z "$LD_PRELOAD" ]; then
    echo "export LD_PRELOAD=/usr/local/lib/libogrt.so"
else
    echo "export LD_PRELOAD=/usr/local/lib/libogrt.so:$LD_PRELOAD"
fi
```

## Epilog

### Removing temporary directories
Create a job epilog to remove the temporary folders created for the job (/etc/slurm/epilog/job.sh)

```
#!/bin/bash
# Remove temporary directories for the job
SCRATCH_DIR=/scratch/jobs/$SLURM_JOB_USER/$SLURM_JOBID
SHM_DIR=/dev/shm/jobs/$SLURM_JOB_USER/$SLURM_JOBID
TMP_DIR=/tmp/jobs/$SLURM_JOB_USER/$SLURM_JOBID
rm -rf $SCRATCH_DIR 2>/dev/null >/dev/null
rm -rf $SHM_DIR 2>/dev/null >/dev/null
rm -rf $TMP_DIR 2>/dev/null >/dev/null
```
