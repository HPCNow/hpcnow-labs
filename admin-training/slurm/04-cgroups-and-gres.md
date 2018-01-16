# Hands-On 04: Cgroups and GRES
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, you will be able to setup CGroups support and basic custom GRES.

*Estimated time: 30 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in hands-on session 01
* Previous hands-on completed

## CGroups 

CGroups is a Linux kernel feature that limits, accounts for, and isolates the resource usage (CPU, memory, disk I/O, network, etc.) of a collection of processes.

CGroups provides the following features but not all of them are exposed in batch queue systems:
* Resource limiting – groups can be set to not exceed a configured memory limit, which also includes the file system cache
* Prioritization – some groups may get a larger share of CPU utilization or disk I/O throughput
* Accounting – measures a group's resource usage, which may be used, for example, for billing purposes
* Control – freezing groups of processes, their checkpointing and restarting

The CGroups adoption in Slurm is the only safe way to suspend jobs in memory, enforce resource limits, and also deliver CPU binding, memory affinity, and GPU access. For this reason, HPCNow! strongly suggests incorporating CGroups in your production environment.

### proctrack/cgroup plugin

The proctrack/cgroup plugin is used for process tracking and suspend/resume capability. proctrack/cgroup uses the freezer subsystem which is (at this time) the most reliable mechanism for tracking and controlling processes in Linux systems.

In order to enable this plugin, we will set up the following parameter in slurm.conf:

```
ProctrackType=proctrack/cgroup
```

<!-- The custom task cgroups hack does not work anymore. Code needs to be updated. - Jordi 2018/01/16
### task/cgroup plugin

The task/cgroup plugin is used for task management which enables the following key features:

* The ability to confine jobs and steps to their allocated cpuset.
* The ability to bind tasks to sockets, cores and threads within their step's allocated cpuset on a node.
* Supports block and cyclic distribution of allocated CPUs to tasks for binding.
* The ability to confine jobs and steps to specific memory resources.
* The ability to confine jobs to their allocated set of generic resources like GPUs.

In order to enable this plugin, we will set up the following parameter in slurm.conf:

```
TaskPlugin=task/cgroup
```

The behaviour of this plugin is defined by cgroup.conf file. There are several options for this plugin. HPCNow! recommends the following options:

* *AllowedRAMSpace=100* this parameter constraints the job cgroup RAM to a percentage of the allocated memory. The default value is 100.

* *AllowedSwapSpace=0* this parameter constraints the job cgroup swap space to a percentage of the allocated memory. The default value is 0, which means that RAM+Swap will be limited to AllowedRAMSpace. Unfortunately, this parameter does not restrict the Linux kernel from using swap space. In order to do so, you also need MemorySwappiness.

* *MemorySwappiness=0* this parameter configures the kernel's priority for swapping out. A value of 0 prevents the kernel from swapping out program data. A value of 100 gives equal priority to swapping out file cache or anonymous pages. Either ConstrainRAMSpace or ConstrainSwapSpace must be set to yes in order for this parameter to be applied.

* *ConstrainRAMSpace=yes* this parameter value constrains the job's RAM usage by setting the memory soft limit to the allocated memory and the hard limit to the allocated memory * AllowedRAMSpace.

* *ConstrainSwapSpace=yes* this parameter value constrains the job's swap space usage, which ideally is 0.

* *TaskAffinity=yes* If configured to "yes" then set a default task affinity to bind each step task to a subset of the allocated cores using sched_setaffinity. The default value is "no". Note: This feature requires the Portable Hardware Locality (hwloc) library to be installed.

Review cgroup.conf man page for more information.

Populate the /etc/slurm/cgroup.conf file with the following content and restart the Slurm daemons: 

```
# Slurm cgroup support configuration file /etc/slurm/cgroup.conf
AllowedRAMSpace=100
AllowedSwapSpace=0
MemorySwappiness=0
ConstrainRAMSpace=yes
ConstrainSwapSpace=yes
TaskAffinity=yes
```
-->

### jobacct_gather/cgroup plugin

The jobacct_gather/cgroup plugin is used for the collection of accounting statistics for jobs, steps and tasks. While the jobacct_gather/cgroup plugin is considered to be a more accurate mechanism, it's slower than the jobacct_gather/linux plugin. HPCNow! suggests using jobacct_gather/linux plugin for HTC and large HPC systems.

In order to enable this plugin, we will set up the following parameter in slurm.conf:

```
JobAcctGatherType=jobacct_gather/cgroup
```

## Generic Resource Scheduling

Generic Resource Scheduling (GRES) allows managing generic consumable resources per node through several plugins.

In order to enable GRES plugins, a comma delimited list of GRES must be provided in the ```GresTypes``` parameter defined in slurm.conf

* *GresTypes* defines the list of generic resources to be managed.
* *Gres* defines the resource configuration details in the format <name>[:<type>][:no_consume]:<number>[K|M|G]

### Configure support for bandwidth

Include bandwidth GRES in GresTypes parameter in the slurm.conf file:

```
GresTypes=bandwidth
```

Setup the nodes.conf file to specify the number of resources available in each node

```
NodeName=hsw[001-512] Gres=bandwidth:no_consume:4G
```

Each compute node with generic resources must also contain a gres.conf file describing which resources are available on the node, their count, associated device files and cores which should be used with those resources. The configuration parameters available are:


Modify gres.conf file to define the nodes that have this special resource

```
# Configure support for our four GPUs, plus bandwidth
NodeName=hsw[001-512] Name=bandwidth Count=4G
```

Finally, restart the Slurm daemons to apply the changes.

### Request GRES in a job

In order to request a specific GRES, the users need to use ```--gres``` or ```#SBATCH --gres``` options at job submission time.

The option requires an argument specifying which generic resources are required and how many resources. The resource specification is of the form name[:type:count]. 

```
sbatch --gres=bandwidth:2G
```
