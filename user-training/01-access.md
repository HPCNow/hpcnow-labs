# Hands-On 01: Getting access to the cluster
In this hands-on, we are going to setup the required software in order to be able to access to the High Performance Computing cluster.

*Estimated time : 15 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

## ToDo

### Install a SSH client

* Windows: download and install [MobaXterm Home Edition](http://mobaxterm.mobatek.net/download-home-edition.html)
* MacOSX: download and install [iTerm2](https://www.iterm2.com/downloads.html)
* Linux: install one of the following programs: Konsole (KDE), Gnome-Terminal (Gnome), Guake, Yakuake
* Multiplatform: [Terminus](https://eugeny.github.io/terminus/)

### Create a SSH key

```
ssh-keygen -t rsa
```

### Transfer the SSH key to the cluster


```
ssh-copy-id -i ~/.ssh/id_rsa username@login.mydomain.com -p 22022
```

:heavy_exclamation_mark: Replace the login node URL (```login.mydomain.com```) with the URL provided by the trainer.
:heavy_exclamation_mark: Replace the ```username``` with the user provided by the trainer.
:heavy_exclamation_mark: The default SSH key is located in the following path ```~/.ssh/id_rsa```. If you have created a different one, replace the path to the SSH key.

### Connect to the login node

```
ssh username@login.mydomain.com -p 22022 -X
```

The login node is meant to be a simple but very secure node to provide access to the files and to manage the batch jobs. It is not suitable for running CPU intensive codes or compile your code. In order to test the code and interact with the command line, you can use the ```interactive``` command line which is explained in hands-on 03.

### Setup alias
The previous command is quite long and easy to forget. You can create an alias for the previous command following these two simple steps in a shell session in your laptop:

```
echo "alias mycluster='ssh username@login.mydomain.com -p 22022 -X'" >> ~/.bashrc
source ~/.bashrc
```

### Download the training material into your home directory:

```
git clone https://github.com/HPCNow/snow-labs
```

