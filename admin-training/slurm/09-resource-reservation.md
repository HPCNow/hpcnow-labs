# Hands-On 09: Resource Reservations
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, you will learn how to setup and manage resource reservations.

*Estimated time: 60 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in hands-on 01
* Previous hands-on completed


## Resource Reservation
A resource reservation defines the resources in that reservation and a time period during which the reservation is available for a limited number of users.

Reservations can only be managed by user root or SlurmUser through the scontrol command. If you want to run those operations as a regular user, you should consider enabling sudo access for the scontrol command.

Any job running in the reservation will be canceled after the reservation reaches its EndTime, unless you have enabled ```ResvOverRun``` in slurm.conf.


### Create a reservation

Slurm can create a reservation for:
* cores [```CoreCnt```]
* nodes [```NodeCnt```]
* licenses [```Licenses```]
* burst buffers [```BurstBuffer```]

The reservations can be filtered or limited to:
* account(s) [```Accounts=uod,git```]
* user(s) [```Users=user07,user08```]
* node(s) [```Nodes=skl[001-004]```]
* feature(s) [```Features=skl```]
* partition(s) [```PartitionName=high,medium```]

The reservations are defined by:
* StartTime: format ```YYYY-MM-DDTHH:MM:SS```
* EndTime: format ```YYYY-MM-DDTHH:MM:SS```
* Duration: format ```DD-HH:MM:SS```

The reservation behavior can be modeled by optional flags (see advanced resource reservation).

```
scontrol create reservation ReservationName=test01 \
         StartTime=2018-01-19T10:00:00 Duration=00:30:00 \
         Users=user07,user04 NodeCnt=256
```

This creates a reservation of 256 nodes, available only for users user01 and user02, starting on 2017-12-12T10:00:00 and it will last for 30 minutes.

The command ```scontrol show res```, lists the reservations defined in the system:

```
scontrol show res
ReservationName=test01 StartTime=2018-01-19T10:00:00 EndTime=2018-01-19T10:30:00 Duration=00:30:00
   Nodes=hsw[001-256] NodeCnt=256 CoreCnt=6144 Features=(null) PartitionName=ondemand Flags=
   TRES=cpu=6144
   Users=user07,user04 Accounts=(null) Licenses=(null) State=INACTIVE BurstBuffer=(null) Watts=n/a
```

### Modify a reservation
Reservations can only be modified by the root user. In this example the duration, node count, and the users granted access can be changed with the following command:

```
scontrol update reservation=test01 NodeCnt=24
```

### Delete a reservation

Reservations are automatically purged once they expire. They may also be manually deleted by root user. 
If there are jobs running on a reservation, this reservation cannot be deleted.


```
scontrol delete reservation=test01
```

### Reservation Use

In order to use the reservation, the job must request it. 

```
sbatch --reservation=test01 -n 1024 -t 00:05:00 --wrap="srun -n 1 sleep 120"
```


## Advanced Resource Reservations


### Scheduled Outage Reservations

Reservations are also useful to define scheduled outages.

```
scontrol create reservation ReservationName=outage_01 \
         starttime=2018-01-19T12:00:00 duration=02:00:00 \
         user=root flags=MAINT,IGNORE_JOBS nodes=ALL
```

The flags:

* ```MAINT``` is used to identify the reservation for accounting purposes as system maintenance. 
* ```IGNORE_JOBS``` is used to indicate that we can ignore currently running jobs when creating this reservation.


### License Reservations

The ```LICENSE_ONLY``` flag is used to indicate that the reservation will prevent any other job requesting those licenses from being scheduled on this cluster during this period of time.


```
scontrol create reservation ReservationName=fluent_user07_01 \
         starttime=2018-01-20T06:00:00 duration=120 \
         Users=user07 flags=LICENSE_ONLY licenses=fluent:1000
```

### Periodic Resource Reservations

The ```DAILY``` flag is used to define periodic reservations occurring in a daily basis. Other options are ```WEEKDAY```, ```WEEKEND```, ```WEEKLY```.

```
scontrol create reservation ReservationName=periodic_01 \
         starttime=2018-01-20T08:00:00 duration=30 \
         Users=user07,user08 flags=DAILY nodecnt=128
```


### Restrict users 

Specific accounts and/or users can be prevented from using reservations with ```-``` symbol. 

In this example, a reservation is created for account "uod", but user "user08" is prevented from using it.

```
scontrol create reservation account=uod user=-user08 \
         starttime=noon duration=60 nodecnt=128
```

### Run Jobs Outside Expired Reservation

When a reservation ends the jobs requesting that reservation will be put into a held state. In order to allow those jobs to run outside the reservation once it's expired, you can use the ```NO_HOLD_JOBS_AFTER_END``` reservation flag.

```
scontrol create reservation ReservationName=purged_01 \
         starttime=2018-01-20T08:00:00 duration=30 \
         Users=user08 flags=NO_HOLD_JOBS_AFTER_END nodecnt=128
```

### Reservations Floating Through Time

The ```TIME_FLOAT``` reservation flag allows defining a reservation with a start time that remains a fixed period of time in the future. These reservations do not accept any job.

This is a nice strategy to prevent long-term jobs from being initiated on specific nodes.

Those reservations may impact the backfilling opportunities. The duration of the reservation must be relatively large in order to allow regular backfilling.

```
scontrol create reservation ReservationName=floating account=root nodes=skl[001-256] \
         starttime=now+60minutes duration=04:00:00 \
         flags=TIME_FLOAT
```

### Reservations that Replace Allocated Resources

The ```REPLACE``` reservation flag allows creating a reservation for which nodes are automatically replaced with new idle nodes, always maintaining a constant size pool of resources.

```
scontrol create reservation ReservationName=replace_test01 \
         StartTime=2018-01-21T10:00:00 Duration=00:30:00 \
         Users=user07,user08 NodeCnt=256 flags=REPLACE
```


### Reservation Purging After Last Job

The ```PURGE_COMP``` reservation flag allows purging the reservation automatically after the last associated job completes. The reservation must be populated within 5 minutes of its start time otherwise it will be purged.

```
scontrol create reservation ReservationName=purge_test01 \
         StartTime=2018-01-21T10:00:00 Duration=00:30:00 \
         Users=user07,user08 NodeCnt=256 flags=PURGE_COMP
```
