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

*Estimated time : 45 minutes*

## Requirements
Cluster account.
Laptop with SSH client.
Slurm created in the hands-on 01

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

If you want, you can simulate a 9152 Intel Knights Landing cluster and call it Cori ;-)

### Setup a partition attending to the walltime limit
1. Modify the following file in order to update the partitions available in the cluster: ```/etc/slurm/partitions.conf```
2. Setup different priority for each partition.

| Partition  |  Walltime  |
| ---------- | ---------- |
| short      | 4 hours    | 
| medium     | 24 hours   | 
| long       | 168 hours  |

### Prevent mixing architectures

In order to prevent mixing architectures in the same job, consider to export the following environment variable in /etc/profile.d/slurm.sh

```
export SBATCH_CONSTRAINT=[hsw|skl|knl] 
```

By default all the jobs will be routed to a unique architecture unless the user request a specific architecture with ```#SBATCH -C bdw``` or ```sbatch -C bdw script.sh```

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

You can create a submit script based on example (right column) or in ~/src/examples

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
su - user01 -c "submit command"
```
