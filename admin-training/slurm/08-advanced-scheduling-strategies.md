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
In this hands-on, you will learn how to setup advanced scheduling strategies, allowing for further improvements in cluster utilization and more equitable sharing of cluster resources.

*Estimated time: 60 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in hands-on 01
* Previous hands-on completed

### Preemption

Job preemption allows stopping one or more "low-priority" jobs to let a "high-priority" job run. Different job preemption mechanisms can be implemented: job suspension, job checkpointing and restart and job cancel.
With job preemption, the **cluster domination by long-term jobs can be mitigated**. By adopting this strategy, you should be able to schedule really large (and high-priority) jobs quite quickly by suspending other low priority jobs.

In Slurm, job preemption can be defined by relative priority between partitions or QoS. Even though QoS provides more options, due to the time constraints of this hands-on session, the job preemption will be handled by partition priority. If you need more flexibility, you should consider implementing QoS and potentially developing a submission plugin for partition or QoS routing.

#### Job preemption based on suspension mechanism

By adopting job suspension as the preemption mechanism, the users could run large and short simulations with a reasonably short waiting time.
With a large number of short single core jobs (including parametric jobs) waiting in the partition, the utilization of the cluster could easily grow to 90%.

Unfortunately, this solution comes with a price. The suspended jobs are bound to the allocated nodes, and it's not possible to resume those jobs until the high priority job is finished; even if you have the resources available to run them.

#### Job preemption based on checkpointing and restart mechanism

Several HPC facilities see the Checkpointing & Restart (C&R) as a "resilience" mechanism because you can restart the job from the last checkpoint and save CPU time in case of a disaster. HPCNow! strongly suggests you consider banning long running jobs (more than ~7 days) if the code doesn't have a checkpointing mechanism or if it's not capable to use 3rd-party C&R software ([SCR](https://computation.llnl.gov/projects/scalable-checkpoint-restart-for-mpi), [DMTCP](http://dmtcp.sourceforge.net/), etc.).

In addition to the resilience benefits, the scheduler could take C&R as a job preemption mechanism, allowing it to migrate preempted jobs to some other resources.

In addition to the mitigation of cluster domination, this could potentially **minimise job scattering** and consequently reduce the latency overhead on MPI jobs. Having said that, C&R is a very expensive operation because it usually involves moving large datasets in the cluster file system. For that reason, the scheduler should be configured in order to reduce excessive use of this mechanism.

Note that in order to integrate C&R capabilities, a filesystem designed for this purpose is required (high bandwidth and low metadata usage).

An ideal scenario should be able to take advantage of backfilling and a combination of job preemption based on job suspension and also job checkpointing and restart.

### Partition limits, priorities, and preemption mechanisms

The following partition schema meets 90% of the most common requirements. If you don't have clarity about your user requirements, the following suggested configuration will give you a good starting point:

| Partition | Nodes | Walltime Limit | Preemption Mechanism | Priority |
| --------- | ----- | -------------- | -------------------- | -------- |
| high      | all   | 4h             | none                 | 50       |
| medium    | all   | 24h            | none                 | 40       |
| low       | all   | 168h           | suspension           | 30       |
| requeue   | all   | 168h           | requeue              | 20       |
| ondemand  | all   | none           | none                 | 10       |

* The high, medium and low partition names refer to the priority (urgency). And this priority is defined based on the walltime limit. The higher the walltime, the lower the priority.
* The high partition is the only partition able to preempt other preemptable partitions, low and requeue, by using job suspension and job requeue respectively. 
* The requeue partition targets those applications that are capable to generate a checkpoint and then restart from last cycle.
* OnDemand partition is on hold by default. The main purpose of this partition is to route jobs requesting a lot of resources or very uneven allocation (large memory but low core count).
* If you want to prevent medium jobs suspending low and requeue partition jobs, you can define the same priority for low and requeue partition in the medium partition (i.e. 25).
* PriorityTier, allows defining a suspension priority. Unfortunately, a partition's priority tier takes precedence over a job's priority.
* Consider setting up one of the following options in SchedulerParameters: 
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

In this example, since medium, low and requeue have the same priority, only the "high" partition will be able to suspend jobs in those partitions. Medium partition jobs will be unable to suspend any job.

In order to avoid exposing the requeue partition by default to all users, you can export the following variable in the user environment. Otherwise, you can also consider developing a submission plugin to route the jobs requesting "requeue" (```SBATCH --requeue```).

Include the following line in /etc/profile.d/slurm.sh
```
export SBATCH_PARTITION=high,medium,low,ondemand
```

Restart the daemon with the following command line:

```
systemctl restart slurmctld
systemctl restart slurmd
```

Submit a long-term job as user user01 (low priority partition):

```
sbatch -n 5000 -t 25:00:00 -C skl --wrap="srun -n 1 sleep 120"
```

Submit a short-term job (high priority partition) requiring one of the nodes allocated for the previous job. i.e.: --nodelist=skl[001-010] in order to force to suspend the low priority job.
```
sbatch --nodelist=skl[001-010] -N 10 -n 400 -t 00:01:00 -C skl --wrap="srun -n 1 sleep 60"
```

Submit a job using application-level checkpointing through requeue partition with user user01. The submit script [periodic_cr.sh](example/periodic_cr.sh) available in the example folder will generate the checkpoint file every 5 seconds. 

Download this file and submit the job with the following command:
```
sbatch --nodelist=hsw001 -n 24 -N 1 -p requeue periodic_cr.sh
```

Once the job is running, submit another one requiring the same node allocated for the previous job in order to force preemption.
```
sbatch --nodelist=hsw001 -n 24 -N 1 -t 00:05:00 --wrap="srun -n 1 sleep 300"
```

Wait for two or three minutes and the requeued job will be migrated to another compute node.
```
squeue -i 2
```

### Prevent cluster domination

The fairsharing mechanism will regulate the priority of the jobs based on who has used more or fewer resources after each cycle. While short-term jobs are nicely handled by backfilling and fair sharing priority; small and **long-term jobs can dominate the cluster** and lock down the resources for other users for a very long period of time. In order to mitigate this risk, you can implement job preemption as detailed above. 

In addition to that, HPCNow! suggests establishing **upper limits for each user and/or group account in order to restrict the resources available at any given time for long-term jobs**. In this scenario (partition based preemption), QoS must be associated with the partitions with Partition QOS (or AllowQos + custom plugin which is not covered in this hands-on).

Partition QoS allows defining the limits that a traditional definition of a partition is not able to do. All the nodes can be assigned to a partition and then in the Partition's QOS limit the number of resources available for that partition (i.e. GrpCPUs or GrpNodes).

By adopting partition QoS the partition priority can be used to define the preemption priority without impacting the overall job priority (weight 0) and the partition QoS associated to each partition can define the priority based on the walltime/urgency.

```
sacctmgr -i add qos high priority=50
sacctmgr -i add qos medium priority=40
sacctmgr -i add qos low priority=30 GrpCPUs=4096 flags=DenyOnLimit
sacctmgr -i add qos requeue priority=20
sacctmgr -i add qos ondemand priority=10 GrpCPUs=2048 flags=DenyOnLimit
```

The expected output should be something like this:
```
sacctmgr show qos format=name,priority,Flags,GrpTRES
      Name   Priority                Flags       GrpTRES
---------- ---------- -------------------- -------------
    normal          0
      high         50
    medium         40
       low         30          DenyOnLimit      cpu=4096
   requeue         20
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

Submit a job array in order to hit the QoS limits implemented with low partition QoS:

```
sbatch -n 500 -t 24:05:00 --array=1-20 -C skl --wrap="srun -n 1 sleep 120"
```

You should be able to see something like this:

```
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        104_[1-20] high,medi     wrap   user01 PD       0:00     13 (Resources)
        105_[9-20] high,medi     wrap   user01 PD       0:00     22 (QOSGrpCpuLimit)
```

### Job scattering mitigation strategies

The following strategies will provide more opportunities for allocating bigger jobs (OpenMP and MPI) in a smaller number of compute nodes which will **reduce waiting times for large jobs and the impact of MPI latency**.

* Fill up the nodes in order (default)
* Fill up the nodes with highest load average first (avoid CR_LLN options)
* Use CPU but also the memory as a consumable resource (SelectTypeParameters=CR_CPU_Memory)
* Allow users with job arrays to bundle several jobs into a single one using complete nodes (consider exposing [the Launcher](https://www.tacc.utexas.edu/research-development/tacc-software/the-launcher) or similar tools to your users)

### Avoid cluster hogging

Cluster hogging is usually generated by **jobs requesting an uneven resource allocation**. For example, jobs requesting a lot of memory (maybe the 90% or the available memory in the node) but only few CPUs. In this scenario, most of the CPUs will be virtually available but not many jobs will have opportunities to run in the shared resources due to the limited amount of memory available.

HPCNow! strongly suggests reviewing the mismatch between the resources requested versus used, especially in terms of CPUs and memory.

In order to avoid those situations, HPCNow! suggests routing jobs requesting four times the default ratio of memory/core to a special partition (ondemand), which could be on hold by default or allowed to run a small number of jobs at a time. If you have large memory nodes, you could also consider routing those jobs to those nodes (custom submission plugin is required).
