# Hands-On 07: Running HPC jobs in containers
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, we are going to setup a realistic container environment based on Singularity using Slurm support for this container technology.

Singularity containers allows users to have full control of their environment and also allows to have the exact user experience in any single place where the container runs.
Singularity containers can be used to package entire scientific workflows, software and libraries, and even data.

It has been widely adopted inside the scientific community because or fairly unique features:
* it allows to share your code with all the required dependencies
* it allows to run a different operating system entirely in order to accommodate complex needs.
* it allows to deploy scientific applications really quickly expect the same experience in a cluster, cloud or in a desktop computer.


*Estimated time : 45 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

# ToDo
Open an interactive session from the login node:

```
interactive
```

## Create a singularity container

You can make and customize containers locally, and then run them on your shared resource. You can even import Docker image content without sudo permissions. Singularity also allows you to leverage the resources of whatever host you are on. This includes HPC interconnects, resource managers, file systems, GPUs and/or accelerators, etc.

The following diagram defines the workflow to create, populate and finally run the singularity container. 

![Singularity Flow](images/singularity-2.3-flow.png?raw=true "Singularity Flow")

source: [http://singularity.lbl.gov](http://singularity.lbl.gov)


### Create a container image

You can create a new container in two simple steps:

* ```singularity create centos7.img``` which creates an empty loopback file image
* ```singularity import centos7.img docker://centos:7``` which imports a docker image

Alternatively, you can create and pull an image from Docker hub (```docker://```) or Singularity Hub (```shub://```) by using one of the following commands:

* ```singularity pull docker://centos:latest```
* ```singularity pull shub://singularityhub/centos:master```

The list of images of each hub are available 
* https://singularity-hub.org/collections
* https://hub.docker.com


### Get into container shell

Execute the following command in order to get a shell into the container:

```
singularity shell singularityhub-centos-master.img
```

Example:

```
snow@skl-210:~$ singularity shell singularityhub-centos-master.img
Singularity: Invoking an interactive shell within container...

Singularity.singularityhub-centos-master.img> id
uid=2000(snow) gid=2000(snow) groups=2000(snow)
Singularity.singularityhub-centos-master.img> ls
centos-latest.img  singularityhub-centos-master.img
Singularity.singularityhub-centos-master.img>
```

Type ```exit``` or press ```Crtl+D``` to leave the shell session.

### Execute custom command into the container


Singularity exec allows to run a custom command into the container. Note that unlike docker exec, the singularity container does not have to be actively running. Example:

```
snow@skl-210:~$ singularity exec singularityhub-centos-master.img ls -lh *.img
-rwxr-xr-x 1 snow snow 345M Aug 11 10:28 centos-latest.img
-rwxr-xr-x 1 snow snow 400M Aug 11 10:27 singularityhub-centos-master.img
```

### Working with files

By default, Singularity mounts /tmp and the home directories. If you want to expose some files from the host into the container, you can use bind options (```-B``` or ```--bind```). Example:

```
singularity exec --bind /projects/:$HOME/projects singularityhub-centos-master.img ls $HOME/projects
```

### Privileged commands

Some actions may require privileged access to the container. In order to do so, you need to use ```sudo``` and ```--writable``` or bootstrap option.
In the cluster, you need to request this action to your support team. Otherwise, you can always setup your own Singularity container in a system where you have privileges and then transfer the container image to the cluster.
You can execute the following command to perform that kind of actions:

```
snow@skl-210:~$ sudo singularity shell --writable singularityhub-centos-master.img
Singularity: Invoking an interactive shell within container...

[root] skl-210:~# mkdir /projects
[root] skl-210:~# exit
```

## Running Singularity containers in Slurm
In order to run singularity containers in your cluster you can use the ```exec``` command or you can take advantage of the Slurm plugin available in sNow! which simplifies the invocation of the container by hiding unnecessary complexity in the implementation.

You can use the following optional argument in ```srun```:

```
srun --image=/path/to/the/image
``` 

or as a sbatch option:

```
#SBATCH --image=/path/to/the/image
```

In both cases, the image is expected to be available in all the compute nodes. So, the image should be located in the shared file system.

### Submit a test job using Singularity

```
sbatch --image=$HOME/singularityhub-centos-master.img --wrap="srun uname -a"
```

## Install Singularity in your workstation 

We strongly suggest to create the basic template of your container in your personal workstation, where you have installed Singularity and you also have sudo privileges. If you want to expose all the instruction sets available in the architecture of your cluster, you may want to transfer the container to the cluster and compile the software there. 

In order to install Singularity in your workstation, just follow these simple instructions:

```
VERSION=2.3.1
wget https://github.com/singularityware/singularity/releases/download/$VERSION/singularity-$VERSION.tar.gz
tar xvf singularity-$VERSION.tar.gz
cd singularity-$VERSION
./configure --prefix=/usr/local
make
sudo make install
```
