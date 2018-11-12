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
# Hands-On 01: Getting access
In this hands-on, we are going to deploy required services to operate a standard High Performance Computing cluster.

*Estimated time : 30 minutes*

## Requirements

* Cluster account.
* Laptop with SSH client.
* sNow! cluster manager already installed

## ToDo


### Setup SSH client
As part of the sNow! cluster manager installation process, you should have sent a SSH key to your email or put a copy onto a pendrive. Transfer the SSH key to your desktop computer in the $HOME/.ssh folder and connect to the sNow! cluster with the following command line:

```
ssh -i ~/.ssh/id_rsa_snow username@snow01.mydomain.com
```

:heavy_exclamation_mark: Replace the login node URL (```snow.mydomain.com```) with the URL provided by the trainer.

:heavy_exclamation_mark: Replace the ```username``` with the username provided by the trainer. By default, the username is *snow*.

:heavy_exclamation_mark: The default SSH key is located in the following path ```~/.ssh/id_rsa_snow```. If you have created a different one, replace the path to the SSH key.

### Connect to the login node

```
ssh -i ~/.ssh/id_rsa_snow username@login.mydomain.com -P 22022 -X
```

The login node is meant to be a simple but very secure node to provide access to files and manage batch jobs. It is not suitable for running CPU intensive programs or compiling code. In order to test the code and interact with the command line, you can use the ```interactive``` command which is explained in section 03 of the user training guide.

### Setup alias
The previous command is quite long and easy to forget. You can create an alias for the previous command by following these two simple steps in a shell session on your computer:

```
echo "alias snow-server='ssh -i ~/.ssh/id_rsa_snow username@snow01.mydomain.com'" >> ~/.bashrc
source ~/.bashrc
```

### Download the training material to your home directory:

```
git clone --recursive https://github.com/HPCNow/snow-labs
```
