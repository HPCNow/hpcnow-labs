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
# Hands-On 00: Overview Demo
In this hands-on, we are going to install a standard High Performance Computing cluster based on a single sNow! server.

*Estimated time : ~3 hours*

## Requirements
The following notes describe how to install a single sNow! server.

This guide assumes that:

1. You have one server dedicated to sNow! (sNow! server) with Debian 9 installed. More information about how to install Debian OS is available [here](https://hpcnow.github.io/snow-documentation/mydoc_install_os_debian.html)
2. The sNow! server will also provide access to share file system via NFS (/home and /sNow). Check the [sNow! documentation](https://hpcnow.github.io/snow-documentation) in order to integrate other cluster file systems like BeeGFS, Lustre or IBM Spectrum Scale.

## Installation
Access to the sNow! server and execute the following commands as root user:
```
cd /sNow
git clone http://bitbucket.org/hpcnow/snow-tools.git
cd snow-tools
./install.sh
```
More information and custom installation options are available [here](https://hpcnow.github.io/snow-documentation/mydoc_install_snow.html)

By default, the only way to access the system as the sNow! or HPCNow! user is by using the SSH key located in the user’s home directory. Note that at this point, those users do not have a password. If you want to enable password access, you will need to setup a password first:
```
passwd snow
```
## Configuration
### Network
Setup the network bridges as explained [here](https://hpcnow.github.io/snow-documentation/mydoc_install_setup_network_bridges.html)
### Hostname Setting
The sNow! server hostname must match with the IP of the snow network bridge (xsnow01). Review your /etc/hosts file and check that it is correct.
Example:
```
127.0.0.1       localhost
YOUR_LAN_IP     snow01-pub.hpcnow.com        snow01-pub
10.1.0.1        snow01
```
### snow.conf
The sNow! configuration file (snow.conf) is the main configuration file of sNow! It provides a complete list of parameters which will be used to setup the HPC cluster.

A template of this file is available in /sNow/snow-tools/etc/snow.conf-example. In order to get started, copy the template file to /sNow/snow-tools/etc/snow.conf and then edit snow.conf to suit your particular needs.
```
cp -p /sNow/snow-tools/etc/snow.conf-example /sNow/snow-tools/etc/snow.conf
```
Be aware that newer releases may include more parameters to setup and migrating from a previous release to a newer one will require you to extend your current snow.conf with some new parameters.

***Warning***: Please ensure this snow.conf file belongs to root:root and has permissions 600 as it will contain passwords in plain text.

This [document](https://hpcnow.github.io/snow-documentation/mydoc_install_snow_conf.html) provides a short description of each parameter.

### Select Roles
Each domain has one or more roles. Each role defines a service or a subset of related services. The roles are scripts which automate the process of deploying a new domain and also configure them based on the parameters available in the main sNow! configuration file (snow.conf).

The following command line, provides a short description for each role available in ```/sNow/snow-tools/etc/roles.d```.

* For more information about sNow! domain roles, visit the [Available Roles](https://hpcnow.github.io/snow-documentation/mydoc_role_available.html) section.
* For more information about how to develop a custom role, visit the [Custom Roles](https://hpcnow.github.io/snow-documentation/mydoc_role_custom.html) section.

```
snow list roles
```
Example output:
```
snow list roles
Role Name                     Description
-------------                 -----------
beegfs                        This role installs BeeGFS server
builder                       Minimal OS to compile code and generate debian packages
cfengine                      Installs CFenfine upon the new guest system
cfs                           Allows to setup NFS client and cluster file system clients (experimental)
deploy                        Installs the required to deploy OS and boot OS via PXE and TFTP. It also provides DHCP and DNS.
docker                        Installs Docker Community Edition and Docker compose
gateone                       Installs Gate One, a web based terminal emulator and SSH client
gdm                           Installs GDM with VNC support.
icinga                        Installs standard HPC alert tool: Icinga.
ldap-master                   Installs LDAP master server.
login                         Installs login node with workload manager clients and creates a new SSH instance allocated in 22022/TCP dedicated to end users.
minimal                       Installs a minimal OS.
monitor                       Installs standard HPC monitoring tools : Ganglia and Icinga.
openvpn_as                    Installs OpenVPN Access Server (2 free client connections for testing purposes).
proxy                         Installs proxy server for HTTP(S),FTP and other relay services (NTP, mail).
puppet                        Installs puppet upon the new guest system.
puppet-master                 Installs puppet master server.
slurmctld-master              Installs Slurm mster server and it can setup the system based on the snow.conf
slurmdbd                      Installs MySQL server and SlurmDB server. It can setup the system based on the snow.conf
snow                          Base role responsible to setup all the required clients and generate the configuration files.
snow_reference_template       Template to help sNow! users to develop their own roles quickly.
snow_template                 Role used to generate the basic image system.
swarm-manager                 Installs and setup Docker Swarm to accommodate docker based services.
swarm-worker                  Installs and setup Docker Swarm to accommodate docker based services.
syslog                        Installs a centralised Rsyslog server to consolidate the logs of the whole cluster.
torque-master                 Installs Torque and Maui. It also generates the install packages for the compute nodes.
xdm                           Installs XDM with VNC support.
```
The file /sNow/snow-tools/etc/active-domains.conf-example contains the most popular roles used in general HPC clusters.

To enable those roles, copy the example file as your working file:
```
cp -p /sNow/snow-tools/etc/active-domains.conf-example /sNow/snow-tools/etc/active-domains.conf
```
### Reboot
The system needs to be rebooted in order to boot with the new kernel, setup the network bridges and initiate the new services.
***Warning***: Review that you can access the server via SSH from a new session.

## Initiate Configuration
The sNow! domain configuration file (domains.conf) provides a table of parameters for each sNow! domain, including the associated roles which define the services provided by each domain (see active-domains.conf) and also the network parameters. This file is generated by executing the snow init command, but it can be modified to accommodate site specific requirements.
```
snow init
```
***Warning***: If the sNow! server is also the NFS server, you will need to restart the NFS daemon at this stage. The standard exportfs -ra will not work.
```
systemctl restart nfs-kernel-server
```
## Domains Deployment
Each domain usually takes between one and two minutes to be deployed and booted, although this will mostly depend on your system's IO performance. More detailed information available (here)[https://hpcnow.github.io/snow-documentation/mydoc_domain_deploy.html].
### Download Domain Template
sNow! relies on pre-built domain images which are used as a template for role deployment. This allows accelerating the deployment of. It is good practice to update this image before creating any new service in order to fix potential bugs.

The following command looks for a new update in the public repository, and if a new update is available, it will download the new image. The size of the image is around 250MB, so expect some delay here.
```
snow update template
```
Some domains have internal dependencies with others. At the time of writing, sNow! is not able to resolve these dependencies, but it will in a future release. The following commands are ordered in such a way that it can resolve the dependencies.

If you want to see what is happening during the deployment process, you can open a new shell and review the output of the log file in real time, using the following command (this is also valid during any interaction with the snow command):
```
tail -f /sNow/log/snow.log
```
In order to deploy the default domains, run the following commands:
```
snow deploy deploy01
snow deploy ldap01
snow deploy syslog01
snow deploy proxy01
snow deploy slurmdb01
snow deploy slurm01
snow deploy monitor01
snow deploy login01
```
## Boot Domains
Once you have deployed all domains, you can boot them all by running the following command:
```
snow boot domains
```
Otherwise, if you want to boot a specific domain, you can run the following command:
```
snow boot <domain_name>
```
## Console Access
In order to get access to any of the domains’ console, execute the following command:
```
snow console <domain_name>
```
In order exit from a console session, use ```<CTRL> ]```.
<!--
## Hardware Stress on Compute Nodes - under development
sNow! installs by default a small OS image which allows stressing the compute nodes to detect potential hardware issues early.
Consider running those tests while you are deploying the first node or customising the deployment templates. This image can also be used to generate the mac addresses database (see next section).
```
snow boot node[001-999] stress-x64
```
-->
## Mac Addresses Gathering
Collecting the MAC addresses in a cluster is simple but can be time-consuming. This [section](https://hpcnow.github.io/snow-documentation/mydoc_node_how_to_collect_the_mac_addresses.html) explains some tricks to avoid spending too much time doing this.

The deployment node will track all the DHCP requests each time a node is booted. Booting the nodes in the desired order will fill the dhcp.leases file in this order. Using the dhcp.leases file you will be able to get all the MAC addresses of your compute nodes which can then be used to assign static IP addresses based on the MAC addresses in the /etc/ethers file. Consider proceeding as follows:
1. Boot the first node and measure the time it takes until it makes its PXE request.
2. Boot the other nodes by giving enough time to avoid a mistake in the order of receiving the DHCP request. Usually, 15 to 30 seconds is enough.
3. Once you have all the nodes up and running, you can take advantage of the following helper script to generate the static IP assignment in the right order.
```
fishermac /var/lib/misc/dnsmasq.leases > /etc/ethers
```
4. Review the content of the /etc/ethers and correct the order of the generated list if required. You can also manually add addresses if needed.
5. Restart the dnsmasq daemon in order to apply the new changes.
6. Transfer the updated version of /etc/ethers to /sNow/snow-configspace/system_files/etc
```
scp -p deploy01:/etc/ethers /sNow/snow-configspace/system_files/etc/
```
## Select Deployment Template
sNow! supports multiple Linux distributions for the deployment for compute nodes. You can list all of the available templates with the following command:
```
snow list templates
```
When setting up a cluster there are actions which only need to be performed once per cluster. In order to do so, sNow! defines an especial role called *golden node* where these actions are to be performed on. In the case of very heterogeneous architectures allocated in the same cluster, these actions may need to be performed once per architecture.
## Compute Node Deployment
If you want to deploy a compute node based on a pre-defined template. You can use the following command (i.e.)
```
snow deploy <first_compute_node> <name_of_the_template>
```
Example:
```
snow deploy n001 centos-7.4-default
```
If you wish to provision the cluster by deploying, replace the n001 with the cluster name or the node range to be deployed.
HPCNow! strongly recommends considering diskless image provisioning to accelerate the provisioning of large clusters. The next two steps detail the process of image gathering and cluster image provisioning.
## Console Access
In order to get access to any of the compute nodes’ console, execute the following command:
```
snow console <node_name>
```
In order exit from a console session, use ```~.```. When connected to an IMPI console, each SSH session captures one ```~``` char. In order to escape from the console session with one ssh server in between, type ```~~.```

## Compute Node Image Gathering
In order to generate the first image, a previously deployed system is required. sNow! supports different types of image-based provisioning. Consider exploring the [image type](https://hpcnow.github.io/snow-documentation/mydoc_image_overview.html) section to learn more about that.

The following example instructs sNow! to gather a stateless image:
```
snow clone node n001 centos-7.4-minimal stateless
```
## Compute Node Image Provisioning
Finally, for provisioning the cluster using a diskless image you only need to execute the following command:
```
snow boot <cluster_name> <image_name>
```
Example:
```
snow boot mycluster centos-7.4-minimal
```
## Modify Single System Image
The following command provides write access to a chroot environment inside a rootfs image. The prompt provided by this command also shows that the shell session is allocated inside a particular image chroot.

In order to exit from this environment, type ```exit``` or press ```Ctrl+d```.
```
snow chroot centos-7.4-minimal
```
