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
# Hands-On 02: Data management

In this hands-on, we are going to work with common tools to manage your data.

*Estimated time : 15 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

# ToDo

## Transferring files back and forth

Now you can transfer the files you have downloaded in the cluster to your laptop. We are going to use different tools and explain the advantages of each one.

### Using a GUI
If you are using MobaXterm, you can use the drang'n'drop user interface which this program offers.

### Using Secure Copy

You can use the command line built-in programme ```scp``` to transfer files. This option usually provides better performance, specially when you have to transfer large amount of data.
It should work on standard Mac and Linux operating systems (in the built-in terminal). It will also work in the MobaXTerm command line on Windows.

To use `scp` to copy the data from your local machine to your cluster, type in the terminal on your local machine.

```
scp -rp -P 22022 <origin_path> username@login.mydomain.com:<destination_path>

```

To use `scp` to copy the data from your cluster to your laptop, type in the terminal on your local machine.

```
scp -rp -P 22022 username@login.mydomain.com:<destination_path> <origin_path>

```

If you have created a new SSH key for accessing to the cluster, you need to specify the path:

```
scp -rp -P 22022 -i ~/.ssh/id_rsa_XXXX <origin_path> username@login.mydomain.com:<destination_path>
```

* Where ```<origin_path>``` and ```<destination_path>``` are the origin path and the expected destination path to your files.
* The ```-P 22022``` indicates the default SSH port in sNow! login nodes.
* The ```-r``` flag indicates to transfer the data contained in a folder recursively
* The ```-p``` flag instructs scp to preserve the time and ownership of each file


### Using rsync

*rsync* is a utility for efficiently transferring and synchronizing files across computer systems, by checking the timestamp and size of files. This option usually takes more time to initiate the file transferring but it allows you to detect variations in large datasets. This is very convinient when you want to syncronise large datasets where only few files are modified/created. Using GUI, ```scp``` or ```sftp``` you will transfer the whole lot, but with ```rsync``` you will be able to avoid to transfer files that have not been modified.

```
rsync -e 'ssh -p 22022' -av <origin_path> username@login.mydomain.com:<destination_path>
```

Options:

* ```-a``` "Archive" mode - permissions and timestamps of the source are replicated at the destination.
* ```-v``` "Verbose".
* ```-n```  "dry run" - don't actually do anything, just indicate what would be done.

### Transfering large amount of data

If you need to transfer really large amoung of data, you should consider to use [High Performance SSH/SCP - HPN-SSH](https://www.psc.edu/hpn-ssh) which is able to provide much better performance than regular SSH. In order to take advantage of HPN-SSH, you need HPN-SSH in the server and also in the client. If don't want to patch your ssh client, you can use this [docker container](https://hub.docker.com/r/yantis/ssh-hpn-x/):

### File System Quotas
Quite often the cluster administrators setup quotas to define upper limits in disk space and number of files in critical portions of shared file systems.
Each cluster file system has its own commands to query how much space and ionodes are left for your home directory or project directory.

#### NFS

```
quota -ugsv -f $HOME
```
#### Lustre

```
lfs quotacheck -ug $HOME
```
#### BeeGFS

BeeGFS does not has quota but quite often Systems Administrators setup a policy engine (RobinHood) which triggers some actions once a user or a group hits a limit. It could be restrict the job submission or disable the user account in the login node.
