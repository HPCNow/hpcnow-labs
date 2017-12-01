# Hands-On 01: Slurm Training Environment Setup
<!--
Copyright (C) 2017 Jordi Blasco
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".
-->
In this hands-on, we are going to setup the required training environment to conduct the next sections of the training. 
The complete training is designed to run in a virtual machine developed by HPCNow!

*Estimated time : 15 minutes*

## Requirements

* Cluster account.
* Laptop with SSH client.

## ToDo

### Install VirtualBox
[Download](https://www.virtualbox.org/wiki/Downloads) the latest stable release of VirtualBox for your platform and the VirtualBox Extension Pack from the official website.
If you already have this software installed, consider to update it to the latest release (if required).

### Setup Host Network
Click on the 'Global Tools' icon and select 'Host Network Manager'.

Create a new host network in order to be able to access to the VM via SSH.

The following examples are based on the following parameters. Change them is you need it.
![Host Network Adapter](../images/virtualbox-host-network-manager-01.png?raw=true "Host Network Manager 01")

![Host Network DHCP](../images/virtualbox-host-network-manager-02.png?raw=true "Host Network Manager 02")

### Download slurm training VM image
The slurm training image can be downloaded from [SuSE Studio](https://susestudio.com/a/MnLYey/slurm-17-02-leap-42-1) or from [HPCNow! repository server](http://snow.hpcnow.com/training/Slurm_17.02_Leap_42.1.x86_64-0.0.14.ovf.tar.gz) (preferred option).

### Import image

Uncompress the tarball in your local disk and import image by clicking on the VirtualBox menu: 'File' -> 'import the appliance'.

### Start the virtual machine and access via SSH
Start the virtual machine and access via SSH with your favorite SSH client:

* host: 192.168.1.1
* port: 22
* user: root
* password: HPCNOW
