# Hands-On 06: Basic Scheduling Strategies
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, you will be able to setup most common scheduling policies and strategies to share computational resources with your user community.

*Estimated time: 60 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in the hands-on 01
* Previous hands-on completed

### Job Submit Plugins
The parameter ```JobSubmitPlugins``` defines a comma delimited the list of job submission plugins to be used. Those plugins allow accommodating site-specific requirements to set default job parameters and/or logging events.

No job submission plugins are used by default but HPCNow! recommends to consider the following plugins:

* *all_partitions*: sets default partition to all partitions on the cluster and routes the jobs to the partitions that meet the requirements.
* *require_timelimit*: force job requests to include time limit
* submit_throttle*: limits the number of job submissions that any single user can submit based upon configuration. The limits are defined by the parameter: ```SchedulingParamters=jobs_per_user_per_hour=#```
* *lua*: enables an easy Lua scripting for interacting with the functions exposed in the Job Submit Plugin API. There are some examples available in [contribs/lua](https://github.com/SchedMD/slurm/tree/master/contribs/lua) directory.


### Backfill Scheduling

Backfill allows running short and small jobs in order to fill up some gaps while a larger job allocation is arranged; achieving this way a better usage of the resources. This option is key to maximise the cluster utilization, but if the scheduler doesn't provide additional mechanisms, the long-term parametric jobs or job arrays could dominate the cluster and large jobs could face unexpected long wait time. In addition to that, backfilling is a very expensive operation from the scheduling point of view. In some situations, it will be required to implement a queue depth limit in order to ensure the expected performance.

The backfill scheduling plugin is loaded by default. Review if backfill scheduling is enabled in slurm.conf. You should be able to see the following parameter value:

```
SchedulerType=sched/backfill
```

The behavior of scheduler is ruled by the ```SchedulerParameters``` values defined in slurm.conf. HCPNow! recommends to consider the following key parameters:

* default_queue_depth=#: specifies the number of jobs to consider for scheduling. The default value is 100 jobs.
* defer: do not attempt to schedule jobs individually at submit time. Which is highly recommended for HTC environments.
* sched_interval=#: defines how frequently, in seconds, the main scheduling loop will execute and test all pending jobs. The default value is 60 seconds.

More options and information are available in the [slurm.conf](https://slurm.schedmd.com/slurm.conf.html) man page.

Modify slurm.conf file and include the following parameters:

```
SchedulerParameters=default_queue_depth=1000
```

### Backfill Scheduling Options

Slurm will be able to manage backfill scheduling more efficiently if the users define reasonable time limits. In order to "encourage" your users to define the time limit, you could use the ```require_timelimit``` defined in this session. Alternatively, in addition to the maximum time limit for each partition, you could define a default time limit when the job doesn't request that. 


Include the following two parameters in the definition of the partitions (partitions.conf)

```
PartitionName=short  Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES  MaxTime=04:00:00  DefaultTime=00:30:00 State=UP
PartitionName=medium Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES  MaxTime=24:00:00  DefaultTime=12:00:00 State=UP
PartitionName=long   Nodes=hsw[001-512],skl[001-512],knl[0001-1024]  Default=YES  MaxTime=168:00:00 DefaultTime=48:00:00 State=UP
```

Note that ```DefaultTime``` is much shorter than ```MaxTime```.

HPCNow! recommends considering the following key list of ```SchedulerParameters``` configuration parameters that can influence the behavior of backfill scheduling.

* bf_continue: allows to continue backfill scheduling after periodically releasing locks for other operations.
* bf_interval=#: defines an interval between backfill scheduling attempts (default value is 30 seconds).
* bf_max_job_part=#: defines the maximum number of jobs to initiate per partition in each backfill cycle. The default value is 0 (no limit).
* bf_max_job_start=#: defines the maximum number of jobs to initiate in each backfill cycle. The default value is 0 (no limit).
* bf_max_job_user=#: defines the maximum number of jobs to initiate per user in each backfill cycle. The default value is 0 (no limit).
* bf_max_job_test=#: defines the maximum number of jobs consider for backfill scheduling in each backfill cycle. The default value is 100 jobs.
* bf_resolution=#: defines time resolution of backfill scheduling (default 60 seconds).
* bf_window=#: defines how long (in minutes) into the future to look when determining when and where jobs can start. By default is one day (1440 minutes).

The default values must be adapted to accommodate site-specific needs. Large clusters and HTC environments usually require larger values for default_queue_depth and bf_max_job_test. The bf_window and  bf_resolution should also be adapted to the time limits implemented in the partitions/QoS.

Modify slurm.conf file and include the following parameters:

```
SchedulerParameters=default_queue_depth=1000,bf_continue,bf_max_job_test=500,bf_resolution=120,bf_window=2880
```

### Multi-Factor Priority

There are six factors in the Multi-factor Job Priority plugin that influence job priority:

* Age: the length of time a job has been waiting in the queue, eligible to be scheduled
* Fair-share: the difference between the portion of the compute resources to share and the amount of compute resources consumed
* Job size: the number of CPUs a job is allocated
* Partition: a factor associated with each node partition
* QoS: a factor associated with each Quality Of Service
* TRES: each TRES Type has its own factor for a job which represents the number of requested/allocated TRES Type in a given partition

#### Multi Factor Priority Options

The behavior of fairshare scheduling is ruled by the following parameters defined in slurm.conf. HCPNow! recommends considering the following key values. More options and information is available in the [slurm.conf](https://slurm.schedmd.com/slurm.conf.html) man page.

* PriorityDecayHalfLife: determines the contribution of historical usage on the composite usage value. The default value is 7-0 (7 days).

* PriorityCalcPeriod: is the period of time in minutes in which the half-life decay will be re-calculated. The default value is 5 (minutes).

* PriorityUsageResetPeriod: interval where the usage of associations will be reset to 0. The default is NONE.

* PriorityFavorSmall: sets the polarity of the job size factor. The default setting is NO.

* PriorityMaxAge: specifies the queue wait time at which the age factor maxes out. The default value is 7-0 (7 days).
* PriorityWeightAge: an integer that scales the contribution of the age factor.
* PriorityWeightFairshare: an integer that scales the contribution of the fair-share factor.
* PriorityWeightJobSize: an integer that scales the contribution of the job size factor.
* PriorityWeightPartition: an integer that scales the contribution of the partition factor.
* PriorityWeightQOS: an integer that scales the contribution of the quality of service factor.
* PriorityWeightTRES: list of TRES Types and weights that scales the contribution of each TRES Type's factor.


If you want to simulate what could happen in one week in only one hour, the production environment values must be divided by a factor 168.
The duration of each job will represent simulated walltime x 168, which means that the job walltime resolution is up to 168 seconds.

The tuned Slurm code available in this VM allows you to try different changes and review the potential impact before to merge those changes into the production environment.  

Edit the slurm.conf and update the parameters with the following values in order to simulate the priority management in short period of time.

```
PriorityType=priority/multifactor
# 1 hours half-life
PriorityDecayHalfLife=01:00:00
# reset usage after 2 hour
#PriorityUsageResetPeriod=2HOURLY
# The larger the job, the greater its job size priority.
PriorityFavorSmall=NO 
# The job's age factor reaches 1.0 after waiting in the queue for 1 hour.
PriorityMaxAge=01:00:00 
# This next group determines the weighting of each of the
# components of the Multi-factor Job Priority Plugin.
# The default value for each of the following is 1.
PriorityWeightAge=1000
PriorityWeightFairshare=10000
PriorityWeightJobSize=1000
PriorityWeightPartition=1000
PriorityWeightQOS=0
```

Finally, you can apply the changes by restarting the daemons.
