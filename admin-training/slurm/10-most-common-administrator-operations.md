## How do I update slurm's configuration?
The slurm configuration needs to be modified on the slurm master node (slurm-01) as root. The configuration files are located in /etc/slurm:

* allowed_devices_file.conf : devices allowed by slurm
* cgroup : folder that contains some configuration regarding to cgroups suspension and affinity.
* cgroup.conf : cgroups setup
* epilog : folder that contains the scripts to be executed in the epilog stage
* gres.conf : configuration of Intel MICs and GPUs nodes
* partitions.conf : configuration of the partitions (aka queues)
* nodes.conf : configuration of the compute nodes (aka queues)
* prolog : folder that contains the scripts to be executed in the prolog stage
* slurm.conf : main config file

After applying some changes in the slurm configuration, you will need to propagate the changes across the cluster, and after that, run “scontrol reconfig”. It's a good practice to review the logs in the system and ensure that all is working perfectly. It's also a good practice to use source control for this configuration

## How do I suspend and reestart jobs?
```
scontrol suspend <jobid>
scontrol resume <jobid>
```
## How do I create a reservation?
```
scontrol create res StartTime=2014-04-01T08:00:00 Duration=5:00:00 Users=jordi NodeCnt=338
Reservation created: jordi_1
```
Update a reservation
```
scontrol update Reservation=jordi_1 Flags=Maint NodeCnt=20
```

Delete a reservation
```
scontrol delete Reservation=jordi_1
```
## How do I use a previously created reservation?
Submit a job and use a reservation to allocate resources (i.e. reservation jordi_1).
```
sbatch --reservation=jordi_1 submitscript.sl
```
## How do I update a node status?
Generally only “DOWN”, “DRAIN”, “FAIL” and “RESUME” should be used. Be aware that some of them requires to add a reason.
Resume
```
scontrol update NodeName=wm074 state=RESUME
```
Drain/Down
```
scontrol update NodeName=wm[081-088] state=DOWN reason="not yet integrated into slurm cluster"
```
## How do I check that high-availability is working?

```
scontrol ping
Slurmctld(primary/backup) at slurm01/slurm02 are UP/UP
```
## How do I dump the current configuration in memory?
```
scontrol show config
```
## How do I modify a requested job allocation?
If changing the time limit of a step, either specify a new time limit value or precede the time with a “+” or “-” to increment or decrement the current +time limit (e.g. “TimeLimit=+30”). In order to increment or decrement the current time limit, the StepId specification must precede the TimeLimit specification.
```
scontrol update jobid=5001 TimeLimit=+10:00:00 # This will increase the time limit 10h mor
```
## How do I increase the priority of a job?
```
scontrol update jobid=5001 priority=3000
```
## Backup
* Generate a backup file with the QoS and accouting associations: sacctmgr dump mycluster File=/var/local/backup/slurm/acct_backup-XXXXX.cfg
* Stop the slurmdbd daemons from slurmdb01: systemctl stop slurmdbd
* Drop the database : mysql -u slurm --password=XXXXXXXXXX slurm_acct_db -e "DROP DATABASE slurm_acct_db;"
* Remove all the files in the spool folder : rm -fr /var/spool/slurm/*
* Start slurmdbd from slurmdb01: systemctl start slurmdbd
* Create the cluster 'mycluster' in the slurm database from slurmdb01: sacctmgr create cluster mycluster
* Start slurmctld in clean mode in the master node (slurm01), wait for 60 seconds and press Ctrl+C: slurmctld -D -c -vvv 
* Load the QoS and accounting associations from the latest backup file : sacctmgr load /var/local/backup/slurm/acct_backup-XXXXX.cfg
