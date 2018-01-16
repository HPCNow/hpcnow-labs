# Hands-On 03: QoS
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on session, you will setup different QoS levels to define useful limits and submit some jobs to this virtual cluster in order to see how it behaves. 

*Estimated time: 30 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in hands-on session 01
* Previous hands-on completed

## QoS

The Quality of Service (QoS) provides more flexibility and freedom compared to partitions (queues). Each job can be associated with a particular QoS which will affect the job in several ways. In this hands-on, we will define job limits and relative QoS priority. In hands-on session 07 we will review job preemption and some other features also provided by QoS.
Visit this [link](https://slurm.schedmd.com/qos.html) for more information regarding QoS.

### Activate the Multi-Factor Priority

In order to enable QoS you will need to activate the 'Multi Factor Priority'. Edit the '/etc/slurm/slurm.conf' and update the 'PriorityType' value with the following value:

```
PriorityType=priority/multifactor
```

Since we want to test the behavior in short period of time, the following values are very small and unrealistic for a production system. Consider updating those values in a real scenario.
We suggest submitting large jobs with short walltimes using different user accounts in order to see how the competition evolves between the users.

```
PriorityDecayHalfLife=00:10:00
PriorityFavorSmall=NO
PriorityMaxAge=00:01:00
PriorityUsageResetPeriod=DAILY
PriorityWeightAge=500
PriorityWeightFairshare=0
PriorityWeightJobSize=500
PriorityWeightPartition=1000
```

Change the previous values and restart the daemons in order to see the impact in the scheduler.

In order to explore the impact of QoS, change the following parameter:

```
PriorityWeightQOS=100000
```

Note that QoS only affects scheduling priority when the multi-factor plugin is loaded.

### Enforce Limits

In order to enforce the QoS limits, the following parameter must be set up:

```
AccountingStorageEnforce=qos,limits
```

Note that if a user/group/job breaches a limit, the job(s) will be pending. Consider setting up the QoS ```DenyOnLimit``` flag in order to deny jobs at submission.


Setup a default QoS (normal) with a priority value 100. 

```
sacctmgr modify qos normal set priority=100
```

This will be applied to all the existing users. Finally, restart the daemons in order to apply the changes:

```
systemctl restart slurmctld
systemctl restart slurmd
```

### Simulate Usage Activity

After that, you will be able to simulate activity and explore the behavior.

You can use a submission script based on the examples folder or use the following long command line:
```
sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'
```

You can submit as a different user with su command line:

```
su - user01 -c "sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'"
su - user02 -c "sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'"
```

### Influence the behavior by playing with the QoS

You can create some additional QoS levels using different values in order to limit a particular user or group of users.

Here are some examples:

Limit the maximum number of CPUs allocated per user:

```
sacctmgr add qos NameOfQoS MaxCpusPerUser=100
```

Add a qos to a user account and change the default QoS for this user:

```
sacctmgr modify user name=user01 set qos+=NameOfQoS defaultqos=NameOfQoS
```

Set QoS priority

```
sacctmgr modify qos NameOfQoS set priority=1000
```

Set Max CPU minutes limit (60 minutes * 24 hours)

```
sacctmgr modify qos NameOfQoS set GrpCPUMins=1440
```

Set Max CPUs per group

```
sacctmgr modify qos NameOfQoS set GrpCpus=1000
```

Set Max Jobs per group

```
sacctmgr modify qos NameOfQoS set GrpJobs=1000
```

Set Max Nodes per group

```
sacctmgr modify qos NameOfQoS set GrpNodes=1000
```

Set Max Submit Jobs per group

```
sacctmgr modify qos NameOfQoS set GrpSubmitJobs=1000
```

