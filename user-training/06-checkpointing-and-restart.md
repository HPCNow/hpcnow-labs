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
# Hands-On 06: Checkpointing and Restart

In this hands-on, we are going to setup checkpointing and restart and how to implement it in your own code.

*Estimated time : 30 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

# ToDo
Open an interactive session from the login node:

```
interactive
```

## Checkpointing and Restart

The native C&R will depend on the used application or code.
- Periodic Checkpointing
  If your code creates a checkpoint file per cycle, and you know how long it takes, you can set a minimum time limit on the job description. If specified, the job may have it's --time limit lowered to a value no lower than --time-min if doing so permits the job to begin execution earlier than otherwise possible. The job's time limit will not be changed after the job is allocated resources. This is performed by a backfill scheduling algorithm to allocate resources otherwise reserved for higher priority jobs. Acceptable time formats include "minutes", "minutes:seconds", "hours:minutes:seconds", "days-hours", "days-hours:minutes" and "days-hours:minutes:seconds".

```
#SBATCH --time-min=HH:MM:SS
```

- Signaled Checkpointing (preferred method)
  If your code can generate the checkpoint after receiving a signal, it will suit much better than the previous option. When a job is within sig_time seconds of its end time, send it the signal sig_num. Due to the resolution of event handling by SLURM, the signal may be sent up to 60 seconds earlier than specified. sig_num may either be a signal number or name (e.g. "10" or "USR1"). sig_time must have integer value between zero and 65535. By default, no signal is sent before the job's end time. If a sig_num is specified without any sig_time, the default time will be 60 seconds. Use the "B:" option to signal only the batch shell, none of the other processes will be signaled. By default all job steps will be signalled, but not the batch shell itself.

```
#SBATCH --signal=[B:]<sig_num>[@<sig_time>]
```

### Native Checkpointing and Restart with signal trapping

```
#!/bin/bash
#SBATCH -J NativeCR
#SBATCH --time=00:15:00
#SBATCH --mem-per-cpu=200
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --open-mode=append
#SBATCH -p requeue
#SBATCH --signal=INT@30
srun ./native_cr || scontrol requeue $SLURM_JOB_ID
```

### Native Checkpointing and Restart with Proactive/Periodic Checkpointing

The --time-min is the minimum time to perform the compute of checkpointable cycle + time to dump the information to the shared filesystem.

```
#!/bin/bash
#SBATCH -J ProactiveCR
#SBATCH --time=00:30:00
#SBATCH --mem-per-cpu=200
#SBATCH --cpus-per-task=1
#SBATCH --open-mode=append
#SBATCH -p requeue
#SBATCH --time-min=00:00:30
srun ./proactive_cr
```
