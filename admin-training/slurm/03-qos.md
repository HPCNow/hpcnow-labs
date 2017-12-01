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
In this hands-on, you will be able to setup different QoS and scheduling strategies, and submit some jobs to this virtual cluster in order to see how it behaves. 

*Estimated time : 30 minutes*

## Requirements
* Cluster account.
* Laptop with SSH client.
* Virtual Slurm environment created in the hands-on 01
* Hands-on 02 completed

## Todo

### Activate the Multi Factor Priority

In order to enable QoS you will need to activate the 'Multi Factor Priority'. Edit the '/etc/slurm/slurm.conf' and update the 'PriorityType' value with the following value:

```
PriorityType=priority/multifactor
```

Since we want to test the behaviour in short period of time, the following values are very short (and unrealistic). Consider to update those values in production systems.
We suggest to submit large jobs with short walltime using different user accounts in order to see how the competition evolves between these users.

```
PriorityDecayHalfLife=00:10:00
PriorityFavorSmall=NO
PriorityMaxAge=00:01:00
PriorityUsageResetPeriod=DAYLY
PriorityWeightAge=500
PriorityWeightFairshare=10000
PriorityWeightJobSize=500
PriorityWeightPartition=1000
```

Change the previous values and restart the daemons in order to see the impact in the scheduler.

In order to explore the impact of QoS, change the following parameter:

```
PriorityWeightQOS=100000
```

Setup a default QoS with a huge priority difference for the existing users and restart the daemons.

Restart the Slurm daemons with the following command line:

```
systemctl restart slurmctld
systemctl restart slurmd
```

### Simulate Usage Activity

After that, you will be able to simulate activity and explore the behaviour.

You can use submit script based on examples folder.
Or use the following long command line:
```
sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'
```

You can submit as a different user with su command line:

```
su - user01 -c "sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'"
su - user02 -c "sbatch -n 512 --array=1-1000 --wrap='env; srun -n 1 sleep 120'"
```

### Influence the behaviour by playing with the QoS

```
sacctmgr add qos NameOfQoS MaxCpusPerUser=100
```

Add a qos to a user account

```
sacctmgr modify user name=user01 set qos+=NameOfQoS defaultqos=NameOfQoS
```

Set QOS priority

```
sacctmgr modify qos NameOfQoS set priority=100
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


