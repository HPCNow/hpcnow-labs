# Hands-On 08: User Management
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, you will be able to setup and manage Slurm users based on shares and accounting.

*Estimated time: 45 minutes*

## Requirements
* Laptop with SSH client.
* Virtual Slurm environment created in the hands-on 01
* Previous hands-on completed


## Enable Slurm Accounting and User Management

Slurm accounting and user management rely on MySQL/MariaDB. If you want to setup fair sharing and/or QoS you will also need to activate the Multi-Factor Priority.

Slurm database allows managing several clusters. Each one with a different SlurmCTLD server or the same server with multiple instances of SlurmCTLD.

Multiclustering and cluster federation provides more freedom setting limits, groups, ACLs or priority. So, if you have several clusters and you want to define different limits attending to the platform, then multi-clustering is the perfect solution for you.

## Account Management 

In this hands-on session, we will setup a new cluster called ```simulator```

```
sacctmgr add cluster simulator
```

### Account Options
The sacctmgr options available for adding or modifying an account are:

* Cluster: to limit an account to a specific list of clusters. The default value is all the available clusters.
* Description: provides a description of the account. The default value is the account name.
* Name: name of the account.
* Organization: name of the organization of the account.
* Parent: defines this account as a child of another account.

This cluster is shared between two institutions, UoD (40% ownership) and GIT (60% ownership). In addition to that, UoD is divided by three departments. All of them with the same share.

Add the following accounts to cluster "simulator" with the commands:

```
sacctmgr -i add account uod Description=UoD Cluster=simulator \
             organization="University of Dalaran" \
             fairshare=40

sacctmgr -i add account git Description=GIT Cluster=simulator \
             organization="Gnomeregan Institute of Technology" \
             fairshare=60

sacctmgr -i add account arcane Description=arcane Cluster=simulator \
             organization="Arcane Department at UoD" \
             parent=UoD fairshare=33

sacctmgr -i add account frost Description=frost Cluster=simulator \
             organization="Frost Department at UoD" \
             parent=UoD fairshare=33

sacctmgr -i add account fire Description=fire Cluster=simulator \
             organization="Fire Department at UoD" \
             parent=UoD fairshare=33
```

If you have more clusters and you are fine sharing the resources and limits across all of them, you can either not specify a cluster or provide a list of clusters with comma separated.

You can modify existing accounts with SQL-like options, using keywords like ```where``` and ```set```:

```
sacctmgr modify account where <options> set <options>
```

Example:

```
sacctmgr modify account where name=UoD \
   cluster=simulator set fairshare=40
```

To remove an account:

```
sacctmgr remove account where name=<account_name>
```

## Setting up users

You can manage users using similar syntax but the options exposed to user management are different.

### User Options

* Account: account(s) to add the user(s) to
* Cluster: to limit the user(s) to a specific list of clusters. The default value is all the available clusters.
* DefaultAccount: defines the default account for the user.
* DefaultWCKey: defines the default wckey for the user.
* Name: username
* NewName: used to rename a user.
* Partition= limits the user(s) to a partition or list of partitions.
* AdminLevel: allows to define accounting privileges to this user. The available options are:

| AdminLevel | privileges |
| ---------- | ---------- |
| None       | Regular user |
| Operator   | add, modify, and remove any database object (user, account, etc), and add other operators |
|            | create/alter/delete reservations |
| Admin      | same level of privileges as an operator|
|            | alter anything on a served slurmctld as if they were the slurm user or root | 

In this hands-on we will add the following users:

```
sacctmgr -i add user user07 Account=git
sacctmgr -i add user user04 Account=arcane
sacctmgr -i add user user05 Account=frost
sacctmgr -i add user user06 Account=fire
sacctmgr -i add user user08 Account=fire,arcane DefaultAccount=arcane
```

You can modify existing accounts with SQL-like options, using keywords like ```where``` and ```set```:

```
sacctmgr modify user where <options> set <options>
```

Example:

```
sacctmgr modify user where name=user08 set DefaultAccount=fire
```

This will change all users with a default account "fire" to account "arcane".

To remove a user:

```
sacctmgr remove user user08 where account=arcane
```
This will remove user "user08" from account "arcane". Since the user "user08" has access to other accounts (fire), those user records will remain.

If associations are enforced (```AccountingStorageEnforce=associations```), any attempt to use other accounts will result in the job being rejected.

In order to review the shares and the fair share, use the following command:

```
sshare -l
             Account       User  RawShares  NormShares    RawUsage   NormUsage  EffectvUsage  FairShare                    GrpTRESMins                    TRESRunMins
-------------------- ---------- ---------- ----------- ----------- ----------- ------------- ---------- ------------------------------ ------------------------------
root                                          1.000000       17511                  1.000000   0.500000                                cpu=0,mem=0,energy=0,node=0,b+
 root                      root          1    0.009901       17511    1.000000      1.000000   0.000000                                cpu=0,mem=0,energy=0,node=0,b+
 git                                    60    0.594059           0                  0.000000   1.000000                                cpu=0,mem=0,energy=0,node=0,b+
 uod                                    40    0.396040           0                  0.000000   1.000000                                cpu=0,mem=0,energy=0,node=0,b+
  arcane                                33    0.132013           0                  0.000000   1.000000                                cpu=0,mem=0,energy=0,node=0,b+
  fire                                  33    0.132013           0                  0.000000   1.000000                                cpu=0,mem=0,energy=0,node=0,b+
  frost                                 33    0.132013           0                  0.000000   1.000000                                cpu=0,mem=0,energy=0,node=0,b+
```

In order to review the associations per cluster, account, user and fairshare:

```
sacctmgr list assoc tree format=cluster,account,user,fairshare
```