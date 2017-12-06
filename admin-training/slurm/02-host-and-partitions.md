# Hands-On 02: Host and Partitions
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, you are going to simulate a very large environment thanks to a tuned Slurm setup. You will be able to setup different hosts and partitions, and submit some jobs to this virtual cluster. Since this is not a real cluster, the commands performed by each job should be very light, like sleep or hostname command.

The configuration that you will be able to set up in this virtual environment should be suitable for production with minor changes.

*Estimated time: 45 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in the hands-on 01

## Todo

### Add new nodes
Modify the following file in order to update the compute nodes available in the cluster: ```/etc/slurm/nodes.conf```
* Add 512 new nodes (hsw[001-512]):
  * 2 sockets & 12 cores/socket
  * 256 GB
* Add 512 new nodes (skl[001-512]):
  * 2 sockets & 20 cores/socket
  * 384 GB
* Add 1024 new nodes (knl[0001-1024]):
  * 1 sockets & 68 cores/socket
  * 4 threads/core
  * 384 GB

The content of the nodes.conf file should look like this:

```
NodeName=hsw[001-512]      NodeAddr=slurm-simulator NodeHostName=slurm-simulator RealMemory=258048  Sockets=2 CoresPerSocket=12  ThreadsPerCore=1 State=UNKNOWN Feature=hsw
NodeName=skl[001-512]      NodeAddr=slurm-simulator NodeHostName=slurm-simulator RealMemory=389120  Sockets=2 CoresPerSocket=20  ThreadsPerCore=1 State=UNKNOWN Feature=skl
NodeName=knl[0001-1024]    NodeAddr=slurm-simulator NodeHostName=slurm-simulator RealMemory=389120  Sockets=1 CoresPerSocket=72  ThreadsPerCore=4 State=UNKNOWN Feature=knl
```

If you want, you can simulate a 9152 Intel Knights Landing cluster and call it Cori ;-)

### Setup a partition attending to the walltime limit
Modify the following file in order to update the partitions available in the cluster: ```/etc/slurm/partitions.conf```

| Partition  |  Walltime  |
| ---------- | ---------- |
| short      | 4 hours    | 
| medium     | 24 hours   | 
| long       | 168 hours  |

```
PartitionName=short  Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES  MaxTime=04:00:00  State=UP
PartitionName=medium Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES  MaxTime=24:00:00  State=UP
PartitionName=long   Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES  MaxTime=168:00:00 State=UP
```

### Prevent mixing architectures

In order to prevent mixing architectures in the same job, consider exporting the following environment variable in /etc/profile.d/slurm.sh

```
export SBATCH_CONSTRAINT="[hsw|skl|knl]"
```

By default all the jobs will be routed to a unique architecture; unless the user requests a specific architecture with ```#SBATCH -C hsw ``` or ```sbatch -C hsw script.sh```

### Restart Slurm Daemons 
Restart the Slurm daemons with the following command line:

```
systemctl restart slurmctld
systemctl restart slurmd
```

### Explore the availability of the new nodes
You can explore the availability and status of the new nodes with the following command:

```
sinfo
```

### Submit a bunch of jobs

You can create a submit script based on examples available in ~/src/examples

```
sbatch ~/src/examples/job_array.sh
```

Or use the following long command line:

```
sbatch -n 512 --wrap='env; srun -n 1 sleep 120'
```

You can populate the virtual cluster with jobs using job arrays : --array=1-1000

```
sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'
```

You can submit as a different user with su command line:

```
su - user01 -c "sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'"
```

The system contains 10 users (user[01-10]) but you can create your own user list and simulate the very similar system to your production environment.

If the load is too high and some job fails, it may drain the virtual frontend node. In order to recover the cluster, execute the following command:

```
scontrol update frontendname=slurm-simulator State=RESUME
```
