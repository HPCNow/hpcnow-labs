# Hands-On 08: Advanced Scheduling Strategies
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, you will be able to setup advanced scheduling strategies which will allow you to increase even more the cluster utilization and also achieve even more fairness access to the shared resources.

*Estimated time: 60 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in the hands-on 01
* Previous hands-on completed

### Preemption

Job preemption allows stopping one or more "low-priority" jobs to let a "high-priority" job run. Different job preemption mechanisms can be implemented: job suspension, job checkpointing and restart and job cancel.
With job preemption, the *cluster domination by long-term jobs can be mitigated*. By adopting this strategy, you should be able to schedule really large (and high-priority) jobs quite quickly by suspending other low priority jobs.

In Slurm, job preemption can be defined by relative priority between partitions or QoS. Even though QoS provides more options, due time constraints of this hands-on session, the job preemption will be handled by partition priority. If you need more flexibility, you should consider to implement QoS and potentially develop a submit plugin for partition or QoS routing.

#### Job Preemption based on suspension mechanism

By adopting job suspension as preemption mechanism, the users could run large and short simulations with a reasonable short waiting time.
A combination of a large number of short single core jobs (including parametric jobs) waiting in the partition, the efficiency of the cluster could grow easily to 90% of utilization.

Unfortunately, this solution comes with a price. The suspended jobs are bound to the allocated nodes, and is not possible to resume those jobs until the high priority job is finished; even if you have resources available to run them.

#### Job Preemption based on Checkpointing and restart mechanism

Several HPC facilities see the Checkpointing & Restart (C&R) as a "resilience" mechanism because you can restart the job from the last checkpoint and save several CPUTime in case of disaster. HPCNow! strongly suggest to consider to ban running long jobs (more than ~7 days) if the code doesn't have checkpointing mechanism or if it's not capable to use 3rd-party C&R software ([SCR](https://computation.llnl.gov/projects/scalable-checkpoint-restart-for-mpi), [DMTCP](http://dmtcp.sourceforge.net/), etc.).

In addition to the resilience benefits, the scheduler could take C&R as job preemption mechanism, allowing to migrate preempted jobs to some other resources.

In addition to the mitigation of cluster monopolization, this could potentially minimise job scattering and achieve this way reduce the latency overhead on the MPI jobs. Having said that, C&R is a very expensive operation because it usually involves moving large datasets in the cluster file system. For that reason, the scheduler should be configured in order to reduce excessive use of this mechanism.

Note that, in order to integrate C&R capabilities, a filesystem designed for this purpose is required (high bandwidth and low metadata usage).

An ideal scenario should be able to take advantage of backfilling and a combination of job preemption based on job suspension and also job checkpointing and restart.

### partition limits, priorities, and preemption mechanisms

The following partition schema meets the 90% of the common requirements. If you don't have clarity about your user requirements, the following suggested configuration will give you a good starting point:

| Partition | Nodes | Walltime Limit | Preemption Mechanism | Priority |
| --------- | ----- | -------------- | -------------------- | -------- |
| high      | all   | 4h             | none                 | 50       |
| medium    | all   | 24h            | none                 | 40       |
| low       | all   | 168h           | suspension           | 25       |
| requeue   | all   | 168h           | requeue              | 25       |
| ondemand  | all   | none           | none                 | 10       |

* The high, medium and low partition names refers to the priority (urgency). And this priority is defined based on the walltime limit. The more walltime, the less priority.
* The high partition is the only partition able to preempt other preemptable partitions, low and requeue, by using job suspension and job requeue respectively. 
* The requeue partition targets those applications that are capable to generate a checkpoint and then restart from last cycle.
* OnDemand partition is on hold by default. The main purpose of this partition is to route jobs requesting a lot of resources or very uneven allocation (large memory but low core count).
* If you want to prevent medium jobs to suspend low and requeue partition jobs, you can define the same priority of low and requeue partition also in the medium partition (i.e. 25).
* PriorityTier, allows defining a suspension priority. Unfortunately, partition's priority tier takes precedence over a job's priority.
* Consider to setup one of the following options in SchedulerParameters: 
  * preempt_strict_order: attempts to preempt only the lowest priority jobs.
  * preempt_youngest_first: attempts to preempt younger jobs over older.

### Activate job preemption based on partition priority

Setup the following two lines in slurm.conf

```
PreemptType=preempt/partition_prio
PreemptMode=suspend,gang
```


Update the partitions.conf as follow:
```
PartitionName=DEFAULT   Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES State=UP OverSubscribe=FORCE:1
PartitionName=high      MaxTime=04:00:00  Priority=50  PreemptMode=off
PartitionName=medium    MaxTime=24:00:00  Priority=25  PreemptMode=off
PartitionName=low       MaxTime=168:00:00 Priority=25  PreemptMode=suspend
PartitionName=requeue   MaxTime=168:00:00 Priority=25  PreemptMode=requeue     GraceTime=120
PartitionName=ondemand  MaxTime=UNLIMITED Priority=10  PreemptMode=off
```

In this example, since medium, low and requeue have the same priority, only "high" partition will be able to suspend jobs in those partitions. Medium partition jobs will be unable to suspend any job.

In order to avoid to expose the requeue partition by default to all the users, you can export the following variable in the user environment. Otherwise, you can also consider developing a submit plugin to route the jobs requesting "requeue" (```SBATCH --requeue```).

Include the following line in /etc/profile.d/slurm.sh
```
export SBATCH_PARTITION=high,medium,low,ondemand
```

Restart the daemon with the following command line:

```
systemctl restart slurmctld
systemctl restart slurmd
```

Submit long-term job as user01 user (low priority partition):

```
sbatch -N 10 -n 5000 -t 25:00:00 -C skl --wrap="srun -n 1 sleep 120"
```

Submit a short-term job (high priority partition) requiring one of the nodes allocated for the previous job. i.e.: --nodelist=skl[001-010] in order to force to suspend the low priority job.
```
sbatch --nodelist=skl[001-010] -N 10 -n 400 -t 00:05:00 -C skl --wrap="sun -n 1 sleep 120"
```

Submit a job using application-level checkpointing through requeue partition with user user01. The first example will expect a Signal in order to generate the checkpoint. The second one will do it periodically. 

```
sbatch ~/src/Fortran/sigex_cr.sh
sbatch ~/src/Fortran/periodic_cr.sh
```

Once the job is running, submit another one requiring one of the nodes allocated for the previous job in order to force preemption.
```
sbatch --nodelist=skl[011-020] -N 10 -n 400 -t 00:05:00 -C skl --wrap="srun -n 1 sleep 120"
```

### Prevent cluster domination

The fairsharing mechanism will regulate the priority of the jobs based on who has used more or fewer resources after each cycle. While short-term jobs are nicely handled by backfilling and fair sharing priority; small and long-term jobs can dominate the cluster and lock down the resources for other users for a very long period of time. In order to mitigate this risk, you can implement job preemption as detailed above. 

In addition to that, HPCNow! suggest considering to setup upper limits per user and/or group accounts in order to restrict the resources available at any given time in the long-term jobs. In this scenario (partition based preemption), QoS must be associated with the partitions with Partition QOS (or AllowQos + custom plugin which is not covered in this hands-on).

Partition QoS allows defining the limits that a traditional definition of a partition is not able to do. All the nodes can be assigned to a partition and then in the Partition's QOS limit the number of resources available for that partition (i.e. GrpCPUs or GrpNodes).

By adopting partition QoS the partition priority can be used to define the preemption priority without impact in the overall job priority (weight 0) and the partition QoS associated to each partition can define the priority based on the walltime/urgency.

```
sacctmgr -i add qos high priority=100
sacctmgr -i add qos medium priority=80
sacctmgr -i add qos low priority=40 GrpCPUs=4096 flags=DenyOnLimit
sacctmgr -i add qos requeue priority=60
sacctmgr -i add qos ondemand priority=10 GrpCPUs=2048 flags=DenyOnLimit
```

The expected output should be something like this:
```
sacctmgr show qos format=name,priority,Flags,GrpTRES
      Name   Priority                Flags       GrpTRES
---------- ---------- -------------------- -------------
    normal          0
      high        100
    medium         80
       low         40          DenyOnLimit      cpu=4096
   requeue         60
  ondemand         10          DenyOnLimit      cpu=2048
```

Note: in order to enable QoS and limits, the ```AccountingStorageEnforce``` must be set to: ```associations,limits,qos``` and the users must exist in the SlurmDBD.

Update the partitions.conf as follow:
```
PartitionName=DEFAULT   Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES State=UP OverSubscribe=FORCE:1
PartitionName=high      MaxTime=04:00:00  Priority=50  QoS=high      PreemptMode=off
PartitionName=medium    MaxTime=24:00:00  Priority=25  QoS=medium    PreemptMode=off 
PartitionName=low       MaxTime=168:00:00 Priority=25  QoS=low       PreemptMode=suspend
PartitionName=requeue   MaxTime=168:00:00 Priority=25  QoS=requeue   PreemptMode=requeue     GraceTime=120
PartitionName=ondemand  MaxTime=UNLIMITED Priority=10  QoS=ondemand  PreemptMode=off
```

Restart the daemon with the following command line:

```
systemctl restart slurmctld
systemctl restart slurmd
```

Submit a job array in order to hit the QoS limits implemented with partition QoS:

```
sbatch -n 500 -t 00:05:00 --array=1-20 -C skl --wrap="srun -n 1 sleep 120"
```

You should be able to see something like this:

```
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        104_[1-20] high,medi     wrap   user01 PD       0:00     13 (Resources)
        105_[9-20] high,medi     wrap   user01 PD       0:00     22 (QOSGrpCpuLimit)
```

### Job scattering mitigation strategies

The following strategies will give more opportunities to allocate bigger jobs (OpenMP and MPI) in a smaller number of compute nodes, which means less waiting time for large jobs and also less impact in the MPI latency.

* Fill up the nodes in order (default)
* Fill up first the nodes with highest load average (avoid CR_LLN options)
* Use CPU but also the memory as consumable resource (SelectTypeParameters=CR_CPU_Memory)
* Allow users with job arrays to bundle several jobs into a single one using complete nodes (consider to expose [the Launcher](https://www.tacc.utexas.edu/research-development/tacc-software/the-launcher) or similar tools to your users)


### Avoid cluster hogging
Cluster hogging is usually generated by jobs requesting an uneven resource allocation. For example, jobs requesting a lot of memory (maybe the 90% or the available memory in the node) but only few CPUs. In this scenario, most of the CPUs will be virtually available but not many jobs will have opportunities to run in the shared resources due to the limited amount of memory available.

HPCNow! strongly suggest reviewing the mismatch between the resources requested versus used, especially in terms of CPUs and memory.

In order to avoid those situations, HPCNow! suggest to route the jobs requesting four times the default ratio of memory/core to a special partition (ondemand), which could be on hold by default or allow to run a small number of jobs at the same time. If you have large memory nodes, you could also consider routing those jobs to those nodes (custom submit plugin is required).
