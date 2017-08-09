# Hands-On 04: Workload Manager
In this hands-on, we are going to interact with the workload manager by submiting different type of jobs, listing and cancelling them.

*Estimated time : 30 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

# ToDo
Connect to the login node

```
ssh username@login.mydomain.com -p 22022 -X
```

## Slurm Workload Manager

Slurm is the software responsible for managing and allocating the cluster resources when you submit a job.
You need to define the job requirements in order to submit a job. The most common used parameters are:

* ```-J JobName``` Job name
* ```--time=DD-HH:MM:SS```: The expected time the job will run for (walltime). Format DD=days, HH=hours, MM=minutes, SS= seconds
* ```--mem-per-cpu=MMMM```: Memory per CPU core (in MB). Default 1GB
* ```--ntasks=X```: Number of MPI tasks. Default 1 task.
* ```--cpus-per-task=Y```: Number of OpenMP threads. Default 1 thread.
* ```--nodes=Z```:  Number of nodes. Default 1 node.

*IMPORTANT*: the more accurary in the job requirements the more efficient the cluster will be.

You can define those requirements as options of the ```sbatch``` command or include them in the submit script headers. Example:

```
#!/bin/bash
#SBATCH -J JobName
#SBATCH --time=08:00:00		# Walltime
#SBATCH --mem-per-cpu=4096	# memory/cpu (in MB)
#SBATCH --ntasks=2		    # 2 tasks
#SBATCH --cpus-per-task=4	# number of cores per task
#SBATCH --nodes=1		    # number of nodes
```

### Nodes and Job States

Nodes states

- up
- down
- idle
- allocated
- mix
- drained

Jobs states

- queued/pending 
- running
- suspended/preempted
- cancelled/completed/failed

### Default priority

Slurm gives each job a priority, and works to free up appropriate resources for the highest-priority job. At regular intervals, Slurm will recalculate the priorities of all jobs. The priority is based on different factors, each one with different weight:

* *Fairshare*: your job will be given an initial score based on your share and your historical use of the cluster, with your recent use being given more weight.
* *Partition priority*: the partitions priority is defined attending to the job lenght. So, the longer is the job, the less priority it will have.
<!-- * *QoS priority*: the QoS priority is defined attending to the urgency of the job. -->
* *Job size*: jobs for which (number of cores) / (walltime) is greater get more priority. 
* *wait time*: a job gets more priority as it waits. This wait-time bonus gradually increases over a certain period of time.
 
## Running a job

### Most common Slurm commands

- *sbatch* - submits a job script
- *scancel* - cancels a running or pending job
- *srun* - runs a command across nodes
- *sbcast* - transfers file(s) to the compute nodes allocated for the job
- *interactive* - opens an interactive job session
- *sattach* - connect stdin/out/err for an existing job or job step
- *squeue* - displays the job queue
- *sq* - squeue wrapper which displays all the jobs
- *squ* - squeue wrapper which only displays your jobs

### Commonly used Slurm variables

- $SLURM_JOBID (job id)
- $SLURM_JOB_NODELIST (nodes allocated for job)
- $SLURM_NNODES (number of nodes)
- $SLURM_SUBMIT_DIR (directory job was submitted from)
- $SLURM_ARRAY_JOB_ID (job id for the array)
- $SLURM_ARRAY_TASK_ID (job array index value)

### Temporary folders
Temporary folders are created for each job. 

- ```$TMP_DIR```
- ```$SHM_DIR```
- ```$SCRATCH_DIR```

### Examples of submitting jobs

Let's submit the first batch job with Slurm. We will do it using the `sbatch` command to interact with Slurm.

```
sbatch -t 00:01:00 --wrap "sleep 30; echo hello world"

```

The options `-t` stands for *time* and sets a limit on the total run time of the job allocation. Note that each partition on which the jobs are run has its own time limit. If the set time limit exceeds the limit for the partition, the job will become "PENDING" (for more information on job statuses, see below).
`--wrap` option means that the following string (in "") will be turned by Slurm in a simple shell script. 


### Monitoring your work on the cluster
The jobs are scheduled in terms of your relative job priority. Slurm can estimate when the job is going to be scheduled (START_TIME). 
The default command to list batch jobs is ```squeue```. sNow! provides an alias which provides additional information like the priority or the estimated starttime.
* sq list all the jobs
* squ list all your jobs

```
squ
```

The output will look more or less like this:

```
snow@login01:~$ squ
    JOBID PARTITION PRIOR     NAME     USER    STATE       TIME  TIME_LIMIT  NODES CPUS   GRES           START_TIME     NODELIST(REASON)      QOS
      452      high  2008 interact     snow  RUNNING      23:23     1:00:00      1   20 (null)  2017-08-09T11:14:54                skl01   normal
```

### How much memory do I need?
If you request more memory than your job actually needs, the job may wait in the queue for much longer than necessary. If you don't request enough memory, your job may crash, or else run very slowly. The best way to ascertain how much memory is needed, is to run ONE job using a large amount of memory, and review the statistics with sacct, after this job is completed.

```
sacct -j 8030  -o JobID,MaxVMSize,ReqMem
       JobID  MaxVMSize     ReqMem
------------ ---------- ----------
8030                       80000Mc
8030.bash       388540K    80000Mc
8030.0        82539432K    80000Mc
```
* The first column is the job id.
* The second column is the total amount of memory used by the job, in kilo-bytes.
* The third column is the requested amount of memory per CPU, in mega-bytes (Mc = mega bytes / cpu).
* The rows reflect the number of 'srun' commands you used in the script. The first two rows are related to the memory used to submit the job, and are rather irrelevant.
* If your application crashed, and the MaxVMSize is close to the ReqMem, it might help to increase the requested memory. 
* If ReqMem is much larger than MaxVMSize, you should request less.

### Job outputs
The default output files are located in the same folder where the job was submitted with the syntax: ```slurm-$SLURM_JOBID.out``` and ```slurm-$SLURM_JOBID.err```.
You can define your own output files with the following options:

* ```-o``` - name of output file. Example: ```-o test.out```
* ```-e``` - name of error file. Example:  ```-e test.err```

### Cancelling jobs
In order to cancel a pending or running job you can execute the following command:
```
scancel [jobid]
```

If you want to cancell all your jobs, you can use the ```-u $USER``` as option. Example:

```
scancel -u snow
```

### Slurm scripts examples

#### Serial example

```
#!/bin/bash
#SBATCH -J SerialJob
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=8G
ml Application
srun serial_binary
```

#### Shared memory (OpenMP) example

```
#!/bin/bash
#SBATCH -J OpenMPJob
#SBATCH --time=01:00:00     # Walltime
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=8   # 8 OpenMP Threads
ml Application
srun openmp_binary
```

#### Distributed memory (MPI) example

```
#!/bin/bash
#SBATCH -J MPIJob
#SBATCH --time=01:00:00     # Walltime
#SBATCH --ntasks=2          # number of tasks
#SBATCH --mem-per-cpu=8G    # memory/cpu
ml Application
srun mpi_binary
```

#### Hybrid example (MPI+OpenMP)

```
#!/bin/bash
#SBATCH -J HybridJob
#SBATCH --time=01:00:00
#SBATCH --ntasks=4
#SBATCH --mem-per-cpu=8G 
#SBATCH --cpus-per-task=8
ml Application
srun hybrid_binary
```

#### Job array example

```
#!/bin/bash
#SBATCH -J ArrayJob
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --array=1-1000
ml Application
srun array_binary "${SLURM_ARRAY_TASK_ID}"
```

#### CUDA example

```
#!/bin/bash
#SBATCH -J GPUJob
#SBATCH --time=01:00:00
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:2
ml Application
srun binary_cuda_mpi
```

#### Real examples
There is a quite extensive list of real applications submit scripts available in the [HPCNow! github](https://github.com/HPCNow/SubmitScripts/blob/master/Slurm/).
Please, feel free to clone and pull new request to include more examples.

## Advanced Features

### Topology Aware Scheduling
If your code is latency sensitive, we suggest to take advantage of the topology aware scheduling and reduce unnecessary latency by limiting the number of switches for the job allocation.
The following option will allow to require topology aware allocation:

```
--switches=<count>[@<max-time>]
```

The count parameter defines the maximum count of switches desired for the job allocation and the max-time (optional) parameter the maximum time to wait for that number of switches. The will job remain pending until it either finds an allocation with desired switch count or the time limit expires. By default the max-time is 5 minutes and the users can request less time but not more than that.
Acceptable time formats include "minutes", "minutes:seconds", "hours:minutes:seconds", "days-hours", "days-hours:minutes" and "days-hours:minutes:seconds".

Another way to achieve the same could be using switches as constraints but this assumes that your Slurm configuration already contemplates that.

### Native job profiling
Slurm native job profiling allows you to gather profiling data from every task and allocated node of your job. At this time the metrics that we can collect are CPU frequency, CPU utilisation, memory consumption (RSS and VMSize) and I/O.
The data is sampled at a fixed rate and is stored in a HDF5 file. Please be aware that the required disk space for the profiling data may be quite large, depending on job size, runtime, and sampling rate.
In order to use this feature, add the following option in the srun command line in your submission script:
 
```
srun --profile=task --acctg-freq=5 your_binary
```

```--acctg-freq``` is the sampling rate in seconds.

 In order to merge the node local files in /scratch/profiling/${USER} to single file, we suggest you add the following line at the end of your submit script
  
```
sh5util -j $SLURM_JOBID -o profile.h5
```

You can visualise the profile data in the cluster using hdfview, or you can transfer it to your desktop computer and visualize it there.
   
```
hdfview.sh profile.h5
```

For more information about profiling with Slurm please see http://slurm.schedmd.com/hdf5_profile_user_guide.html 
