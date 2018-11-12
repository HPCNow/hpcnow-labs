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
# Hands-On 03: Working environment

In this hands-on, we are going to interact with the common cluster user working environment.

*Estimated time : 15 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

## ToDo
Access to the login node

### Understand difference between login and compute nodes

As mentioned in the first hands-on session, the login nodes are meant to be simple but very secure nodes to provide access to the files and to manage the batch jobs.
Those nodes are not suitable for running CPU intensive codes or compile your code. Actually, the binaries generated in the login nodes may not be compatible with the compute node or able to take advantage of the expected performance of the compute nodes.

In order to test the code and interact with the command line, you can use the ```interactive``` command explained in the next section.

**The login nodes are used for:**
 - running batch jobs
 - performing IO intensive operations
 - pre and post processing simulations and/or analysis
 - visualize data
 - performing memory intensive operations

**The login nodes are used for:**
 - access to the cluster
 - access to your home and project directories
 - upload your data and/or the code
 - download the results
 - submit and manage batch jobs
 - initiate an interactive job session

The following diagram represents the path to get access to HPC resources:
![User Environment](images/user_environment.png?raw=true "User Environment")
### Interactive command
The interactive command allows you to get a remote shell session in a real compute node. This ensures that you will have the same user experience in an interactive session and in a batch job. At the same time, because it is an slurm job, your code is exposed to the same Slurm user environment which will be available in the batch job.
This is specially important when you want to test core binding, memory affinity or MPI launchers.

Because interactive is using valuable resources (real compute nodes) there is a default timeout for inactivity. Which means that after 5 minutes of inactivity, the interactive session is going to be killed and the content of the temporary folders is going to be removed (```$SHM_DIR```, ```$TMP_DIR```, ```$SCRATCH_DIR```).

```
Usage: interactive [-A] [-a] [-c] [-m] [-J] [-e]

Optional arguments:
     -A: account (non-default account)
     -p: partition (default: )
     -a: architecture (default: , values hsw=Haswell skl=SkyLake wsw=Warsaw)
     -n: number of tasks (default: 1)
     -c: number of CPU cores (default: 1)
     -m: amount of memory (GB) per core (default: 1 [GB])
     -e: email address to which the begin session notification is to be sent
     -r: specify a reservation name
     -w: target node
     -J: job name
     -x: binary that you want to run interactively
example : interactive -A snow -a hsw -c 4 -J MyFirstInteractiveJob
example : interactive -A snow -a hsw -c 4 -J MyFirstInteractiveJob -x "MyBinary MyOptions"

Written by: Alan Orth <a.orth@cgiar.org>
Modified by: Jordi Blasco <jordi.blasco@hpcnow.com>
```

You can define your own preferences in ```$HOME/.slurm.env```. In order to do so, copy the default values into your home directory:

```
cp -p /sNow/snow-tools/etc/slurm.env $HOME/.slurm.env
```
And update the values as you wish. Example

```
DEF_PARTITION=interactive
DEF_ARCH=skl
DEF_MEM_PER_CPU=4
DEF_NUM_CPUS=4
DEF_NUM_TASKS=1
DEF_JOB_NAME=interactive
DEF_TIME=01:00:00
SRUN_BIN=/usr/bin/srun
#SRUN_OPTS="-n1 -N1 --mem-per-cpu=0 --pty --preserve-env --mpi=none -x11"
SRUN_OPTS="-n1 -N1 --mem-per-cpu=0 --pty --preserve-env --mpi=none"
INTERACTIVE_SHELL=/bin/bash
INTERACTIVE_SHELL_OPTS=" "
```

### Initiate an interactive job session:

```
interactive
```

### Available software
You can use a variety of software already installed on the cluster. The software is usually build with EasyBuild by the SysAdmins of the cluster and accessible using LMOD.

### User Environment
LMOD is very useful to manage environment variables for each application and it is very easy to use. It loads the needed environment by a certain application and its dependencies automatically. The command line is fully compatible with the previous 'Environment Modules', and it provides simple short-cuts and advanced features.

Syntax :```module [options] sub-command [args ...]```

#### Loading/Unloading sub-commands
* ```load | add``` : load module(s)
* ```del | unload```: Remove module(s), do not complain if not found
* ```purge```: unload all modules
* ```update```: reload all currently loaded modules.

#### Listing / Searching sub-commands
* ```list```: List loaded modules
* ```avail | av```: List available modules
* ```avail | av string```: List available modules that contain "string".
* ```spider```: List all possible modules
* ```spider``` module" List all possible version of that module file
* ```spider``` string: List all module that contain the "string".

#### Short-cuts
LMOD reduce the complexity of module syntax and also the chances to make a mistake while typing the command :-)
All the examples used in these hands-on sessions are using ```ml`` short-cut.
* ```ml``` - is a wrapper for module and also means ```module list```
* ```ml foo bar``` - means: module load foo bar
* ```ml -foo -bar baz goo``` - means: module unload foo bar; module load baz goo;

More information at http://www.tacc.utexas.edu/tacc-projects/lmod
