# Hands-On 00: Build and Install Slurm
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
[ *OPTIONAL* ] This hands-on will teach you how to build and install Slurm packages for production. The packages generated during this hands-on are not going to be used in training environment to conduct the next sections of the training. This hands-on will focus on CentOS (RHEL) and SuSE Leap (SLES).

The process of building the Slurm packages can be simplified by taking advantage of the HPCNow! repositories: 
* http://snow.hpcnow.com/apt/ (Debian and Ubuntu based distributions) 
* http://snow.hpcnow.com/rpm/ (Red Hat and SuSE based distributions)

The installation of Slurm database and controller servers can be automated by taking advantage of the [sNow! roles](https://hpcnow.github.io/snow-documentation/mydoc_available_roles.html).

*Estimated time : 60 minutes*

## Requirements
* NFS server or cluster file system
* two slurm servers with NFS or cluster file system client
* Laptop with SSH client.


## Download sources
The latest Slurm releases can be downloaded from here: https://www.schedmd.com/downloads.php
Other releases can be downloaded from the official GitHub project: https://github.com/SchedMD/slurm/releases

## Pre-requisites
Make sure that you have synchronised clocks and also consistent users and groups (UIDs and GIDs) across the cluster. No user login in the SlurmDBD and SlurmCTLD servers are required but those daemons need to have access to a consistent UID and GID in order to define and apply ACLs/QoS and accounting. 


The following two commands will enable and initiate the NTP daemon:

```
systemctl enable ntpd
systemctl start ntpd
```

The output of the following commands should be consistent across the cluster:

```
systemctl status ntpd
getent passwd munge
getent passwd slurm
```

## Munge
MUNGE (MUNGE Uid 'N' Gid Emporium) is an authentication service for creating and validating credentials. It is designed to be highly scalable for use in an HPC cluster environment. Slurm relies on this service, and this service relies on NTP.

* Make sure that all nodes in your cluster have the same MUNGE key (/etc/munge/munge.key)
* Make sure the MUNGE daemon (munged) is started before you start the SLURM daemons.

* SuSE based distributions: ```zypper -n install munge munge-devel```
* Redhat based distributions: ```yum install -y munge munge-devel```

Generate the MUNGE key and define the right ACLs:

```
dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 600 /etc/munge/munge.key
systemctl enable munge
systemctl start munge
```

Transfer the MUNGE key to another node and test the service:

```
[root@slurm00 ~]# munge -n | ssh slurm01 unmunge
STATUS:           Success (0)
ENCODE_HOST:      slurm00 (192.168.1.3)
ENCODE_TIME:      2013-11-02 04:32:00 (1383319920)
DECODE_TIME:      2013-11-02 04:32:01 (1383319921)
TTL:              300
CIPHER:           aes128 (4)
MAC:              sha1 (3)
ZIP:              none (0)
UID:              root (0)
GID:              root (0)
LENGTH:           0
```

## Dependencies
In order to build the Slurm packages some development packages are required. The following instructions will guide you to install all the missing dependencies required to build the Slurm with most common funcionalities.

### SuSE based distributions

For SuSE distributions you will need the two SLES SDK DVD in your repository. In order to have HDF5 support for Slurm profiling, you will also need to add the following repository:

```
zypper ar http://download.opensuse.org/repositories/science/SLE_11_SP3/science.repo
```

Install the following packages:
```
zypper -n --no-gpg-checks in --type pattern Basis-Devel 
zypper -n --no-gpg-checks in tk git-core openssl-devel libxml2-devel libcgroup-devel libcgroup1 hwloc hwloc-devel hwloc-lstopo hwloc-doc libapr1-devel libconfuse-devel
zypper -n --no-gpg-checks in ncurses-utils ncurses-devel gtk2 gtk2-devel 
zypper -n --no-gpg-checks in rrdtool rrdtool-devel
zypper -n --no-gpg-checks in lua lua-devel linux-kernel-headers 
zypper -n --no-gpg-checks in readline-devel pam-devel numactl numactl-devel
zypper -n --no-gpg-checks in mysql-server mysql-devel freeipmi
zypper -n --no-gpg-checks in hdf5 hdf5-devel
```

### Red Hat based distributions

```
yum groupinstall 'Development Tools' -y
yum install ncurses ncurses-devel gtk2 gtk2-devel rrdtool rrdtool-devel  -y
yum install libcgroup libcgroup-devel hwloc hwloc-devel lua lua-devel -y
yum install kernel-headers  -y
yum install readline-devel openssl-devel pam-devel -y
yum install numactl numactl-devel -y
yum install mariadb mariadb-libs mariadb-devel -y
yum install freeipmi -y
yum install hdf5 hdf5-devel -y
yum install perl-DBI perl-Switch -y
```

Some distributions may require to disable SELINUX and to include firewall rules to enable communication with the slurmdbd and slurmctld nodes.

Check SELINUX status with:

```
cat /etc/sysconfig/selinux | grep disabled
```

Check IPTABLES status with:

```
systemctl status iptables
iptables -L
```


## Build Slurm packages

Download the last stable release for slurm and build the RPMs on the slurm-001

```
wget https://download.schedmd.com/slurm/slurm-17.11.2.tar.bz2 
rpmbuild -ta --with lua --with pam \
          slurm-17.11.2.tar.bz2  | tee rpmbuild-slurm-17.11.2.log
```

Note: SuSE based distributions require to remove munge-libs from BuildRequires in the slurm.spec
```
diff -ru slurm-17.02.7/slurm.spec slurm-17.02.7.bkp/slurm.spec
--- slurm-17.02.7/slurm.spec	2017-08-14 17:48:43.000000000 +0000
+++ slurm-17.02.7.bkp/slurm.spec	2017-08-31 11:33:18.288000000 +0000
@@ -255,7 +255,7 @@
 Summary: Slurm authentication and crypto implementation using Munge
 Group: System Environment/Base
 Requires: slurm munge
-BuildRequires: munge-devel munge-libs
+BuildRequires: munge-devel
 Obsoletes: slurm-auth-munge
 %description munge
 Slurm authentication and crypto implementation using Munge. Used to

```

## Install Slurm packages:

Install all the packages generated:

```
rpm -ivh /root/rpmbuild/RPMS/x86_64/slurm-*
Preparing...                ########################################### [100%]
   1:slurm-plugins          ########################################### [  7%]
   2:slurm                  ########################################### [ 14%]
   3:slurm-perlapi          ########################################### [ 21%]
   4:slurm-devel            ########################################### [ 29%]
   5:slurm-sql              ########################################### [ 36%]
   6:slurm-slurmdbd         ########################################### [ 43%]
   7:slurm-pam_slurm        ########################################### [ 50%]
   8:slurm-sjobexit         ########################################### [ 57%]
   9:slurm-slurmdb-direct   ########################################### [ 64%]
  10:slurm-torque           ########################################### [ 71%]
  11:slurm-blcr             ########################################### [ 79%]
  12:slurm-lua              ########################################### [ 86%]
  13:slurm-munge            ########################################### [ 93%]
  14:slurm-sjstat           ########################################### [100%]
```

Some distributions require to create the SlurmUser prior to starting Slurm and must exist on all nodes of the cluster with the same ID and GID. 
In order to enable full support for cgroups, SlurmUser must be root user, as required by slurmd. SlurmCTLD and SlurmDBD require the same SlurmUser for consistency.


```
groupadd -g 10000 slurm
adduser -u 10000 -g 10000 -s /bin/false slurm
```

The parent directories for Slurm log files, PID files, state save directories, etc. are not created at the installation time. 
They must be created and made writable by SlurmUser as required prior to starting Slurm daemons.

Review the ACLs of the following folders as it could evolve to a security issue. Define umask=0022.

```
mkdir /var/log/slurm
chown -R slurm:slurm /var/log/slurm

```

## High Availability

A backup controller should be defined in order to take over for the primary slurmctld whenever it fails. The backup controller is defined by BackupController parameter in the slurm.conf.

The backup controller should be hosted on a different hardware. However, both hosts should mount a common file system defined by StateSaveLocation in the slurm.conf.

By default, the backup controller detects when the primary fails and takes over for it. When the primary returns to service, it notifies the backup. At that point, the backup saves state and returns to backup mode.

The SlurmDBD server must be installed in a different server(s), otherwise the native high availability will not work.

The Slurm provides native high availability for the SlurmCTLD but not for SlurmDBD. Clusters managed by sNow! can also take advantage of additional high availability layers, achieving this way, the resilience required for a mission critical environment. More information [here](https://hpcnow.github.io/snow-documentation/mydoc_available_roles.html#slurmdbd).

## Setup SlurmDBD and MySQL

MySQL (or MariaDB) should be configured in order to enable QoS and accounting (fair sharing).

Assuming that you have a fresh installation, you should setup the root password for MySQL:

```
/usr/bin/mysqladmin -u root password 'MySQL_ROOT_PWD'
/usr/bin/mysqladmin -u root -h slurmdb01 password 'MySQL_ROOT_PWD'
```

Create the slurm database user:

```
mysql -u root -p
create database slurm_acct_db;
grant all on slurm_acct_db.* to slurm@localhost identified by 'PASSWORD_TO_CHANGE';
grant all on slurm_acct_db.* to slurm@'slurm01' identified by 'PASSWORD_TO_CHANGE';
grant all on slurm_acct_db.* to slurm@'slurm02' identified by 'PASSWORD_TO_CHANGE';
```

Update the slurmdbd.conf file with the MySQL credentials and initiate the slurmdbd service in the slurmdb server:

```
systemctl start slurmdbd
```

Create the cluster in the database with the following command:

```
sacctmgr -i create cluster NameOfMyCluster
```

Finally, check if the installation has been done successfully. You should be able to see several tables populated by SlurmDBD.
# mysql -u root -p
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| slurm_acct_db      |
| test               |
+--------------------+
4 rows in set (0.00 sec)
mysql> use slurm_acct_db;
mysql> show tables;
+---------------------------------------+
| Tables_in_slurm_acct_db               |
+---------------------------------------+
| acct_coord_table                      |
| acct_table                            |
.........

