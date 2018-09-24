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
In this hands-on session, we are going to set up the required training environment to conduct the following sections of the training guide. 
The training material is designed to run on a virtual machine developed by HPCNow!

*Estimated time: 15 minutes*

## Requirements
* Laptop with SSH client.

## ToDo

### Install VirtualBox
[Download](https://www.virtualbox.org/wiki/Downloads) the latest stable release of VirtualBox for your platform and the VirtualBox Extension Pack from the official website.
If you already have this software installed, consider updating it to the latest release (if required).

### Setup Host Network
Click on the 'Global Tools' icon and select 'Host Network Manager'.

Create a new host network in order to be able to access to the VM via SSH.

The following examples are based on the following parameters. Change them as required.
![Host Network Adapter](../images/virtualbox-host-network-manager-01.png?raw=true "Host Network Manager 01")

![Host Network DHCP](../images/virtualbox-host-network-manager-02.png?raw=true "Host Network Manager 02")

### Download slurm training VM image
The slurm training image can be downloaded from [HPCNow! repository server](http://snow.hpcnow.com/training/slurm/). 

<!--
The default format is *OVF Virtual Machine* but other options are also available.
* [OVF Virtual Machine / ESXi (.ovf)](http://snow.hpcnow.com/training/slurm/Slurm_17.11_Leap_42.1.x86_64-0.0.11.ovf.tar.gz)
* [VMware Workstation / VirtualBox (.vmdk)](http://snow.hpcnow.com/training/slurm/Slurm_17.11_Leap_42.1.x86_64-0.0.11.vmx.tar.gz)
* [Preload ISO (.iso)](http://snow.hpcnow.com/training/slurm/Slurm_17.11_Leap_42.1.x86_64-0.0.11.iso)
* [SUSE Cloud / OpenStack / KVM (.qcow2)](http://snow.hpcnow.com/training/slurm/Slurm_17.11_Leap_42.1.x86_64-0.0.11.qcow2.tar.gz)
-->

### Import image

Extract the tarball (Slurm_17.11_Leap_42.1.x86_64-0.0.11.ovf.tar.gz) on your local disk and import image by clicking on the VirtualBox menu: 'File' -> 'import the appliance'.

Set the following parameters:

* name: slum-simulator
* cpus: 4
* memory: 4096 MB

With those hardware resources, you will be able to simulate one of the top 10 in the [www.top500.org](https://www.top500.org/). If you don't have enough resources, keep in mind that the system simulated will be smaller.

Once you have imported the VM, go to VM settings and change the first network interface to NAT, and the second network interface to host-only adapter.

![first network interface](../images/virtualbox-nic-01.png?raw=true "first network interface")

![second network interface](../images/virtualbox-nic-02.png?raw=true "second network interface")

### Start the virtual machine and access via SSH
Start the virtual machine and access via SSH with your preferred SSH client:

* host: 10.1.1.1
* port: 22
* user: root
* password: HPCNOW
