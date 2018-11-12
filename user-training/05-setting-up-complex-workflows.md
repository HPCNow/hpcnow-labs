<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".

HPCNow!, hereby disclaims all copyright interest in this document
`snow-labs' written by Jordi Blasco.
-->
# Hands-On 05: Setting Up Complex Workflows

In this hands-on, we are going to setup complex workflows based on real life applications.

*Estimated time : 30 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

# ToDo
Open an interactive session from the login node:

```
interactive
```

## Job array based on multiple input files or parameters
If you need to explore several parameters or to use several input files you can create a mapping file like params.dat and use a single array job description file to run all the simulations.
The script ```array_builder.sh``` is a simple example that generates the params.dat file. In this case, the params.dat contains 500 lines.

```
#!/bin/bash
#SBATCH -J JobArray
#SBATCH --time=01:00:00     # Walltime
#SBATCH --mem-per-cpu=1G
#SBATCH --array=1-500       # Array definition
PARAMETERS=$(sed -n ${SLURM_ARRAY_TASK_ID}p params.dat)
srun your_binary $PARAMETERS
```

You can generate a file with multiple parameters to explore using the same binary with a simple script:

```
#!/bin/bash
for o in $(seq 2 2 2); do
    for po in $(seq 2.5 0.5 10.000); do
        for osc in $(seq 2 .25 2.00); do
            for freq in $(seq .6 .2 .800); do
                echo "${osc} ${freq} ${po} 1500 ${o}" >> params.dat
            done
        done
    done
done
```

## Job dependencies

### Chain Jobs

You can use chain jobs to create dependencies between jobs.
This is often the case if a job relies on the result of one or more preceding jobs.
Chain jobs can also be used if the runtime limit of the batch queues is not sufficient for your job.
SLURM has an option -d or "--dependency" that allows to specify that a job is only allowed to start if another job finished.
Here is an example how a chain job can looks like, the example submits 3 jobs (Pre-Processing Job, MPI job and finally the Post-Processing Job) that will be executed on after each other

```
#!/bin/bash
TASKS="pre-processing.sl mpi.sl post-processing.sl"
DEPENDENCY=""
for TASK in $TASKS ; do
    JOB_CMD="sbatch"
    if [ -n "$DEPENDENCY" ] ; then
        JOB_CMD="$JOB_CMD --dependency afterok:$DEPENDENCY"
    fi
    JOB_CMD="$JOB_CMD $TASK"
    echo -n "Running command: $JOB_CMD  "
    OUT=`$JOB_CMD`
    echo "Result: $OUT"
    DEPENDENCY=`echo $OUT | awk '{print $4}'`
done
```

## Master/slave program example

```
#!/bin/bash
#SBATCH -J MasterSlave
#SBATCH --time=01:00:00     # Walltime
#SBATCH --ntasks=4          # number of tasks
#SBATCH --mem-per-cpu=8G
srun --multi-prog multi.conf
```

The content of multi.conf file example:

```
0      echo     'I am the Master'
1-3    printenv SLURM_PROCID
```
