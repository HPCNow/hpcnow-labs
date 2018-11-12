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
# Hands-On 1: Docker Swarm Introduction
In this hands-on, we are going to learn how to interact with Docker Swarm cluster provisioned with sNow! cluster manager.

*Estimated time : ~1 hour*

## Requirements
The following notes describe how to interact with a Docker Swarm cluster provisioned with sNow! cluster manager.

This guide assumes that:

1. You have at least one sNow! server. Ideally, one sNow! server and three compute nodes for production ready environment.
2. The sNow! server will also provide access to share file system via NFS (/home and /sNow). Check the [sNow! documentation](https://hpcnow.github.io/snow-documentation) in order to integrate other cluster file systems like BeeGFS, Lustre or IBM Spectrum Scale.

## Installation
Docker Swarm manager nodes implement the Raft Consensus Algorithm to manage the global cluster state.
This is key for managing and scheduling tasks in the cluster, and also storing the same consistent state.

Raft tolerates up to (N-1)/2 failures and requires a majority or quorum of (N/2)+1 members to agree on values proposed to the cluster. This means that the size of the cluster should be at least 3 to resist one node failure or 5 to resist 3 nodes failures.

This hands-on assumes that you have already deployed three VMs (domains) dedicated for Docker Swarm cluster or three compute nodes (production solution).

By default manager nodes also act as a worker nodes. For a small systems or non-critical services, this is relatively low-risk.
However, because manager nodes use the Raft consensus algorithm to replicate data in a consistent way, they are sensitive to resource starvation. In sNow! environment you can isolate managers in VMs without running other services and deploy few bare metal nodes as Docker Swarm workers. In order to do so, you can drain manager nodes to make them unavailable as worker nodes:
```
docker node update --availability drain <NODEID>
```
<!--
### Option 1: Deploy Docker Swarm in VMs
Assuming that you have already defined three VMs (domains) dedicated for Docker Swarm cluster:

```
snow add domain swarm01 --role swarm-manager
snow add domain swarm02 --role swarm-worker
snow add domain swarm03 --role swarm-worker
snow deploy swarm01
snow deploy swarm02
snow deploy swarm03
```
### Option 2: Deploy Docker Swarm in three compute nodes (production solution)
Assuming that you have already defined three nodes dedicated for Docker Swarm cluster:

```
snow add node swarm01 --role swarm-manager
snow add node swarm02 --role swarm-worker
snow add node swarm03 --role swarm-worker
snow deploy swarm01
snow deploy swarm02
snow deploy swarm03
```
-->
## Swarm Interaction

### 1. Check the status of the Docker Swarm cluster
```
snow@swarm01:~$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
hxakgodvxtz9ynsc0nniyz7ol *   swarm01             Ready               Active              Leader              18.03.1-ce
t3z5ru9ssu20b7a9i9bj4p5sl     swarm02             Ready               Active                                  18.03.1-ce
o4vbamp797i2yrvo7anqlgd8y     swarm03             Ready               Active                                  18.03.1-ce
```

### 2. Deploy the first application component as Docker service
The following example will create a very simple container running one hour sleep as a service.
```
snow@swarm01:~$ docker service create --name sleep_app alpine sleep 3600
8o9bicf4mkcpt2s0h23wwckn6
overall progress: 1 out of 1 tasks
1/1: running   [==================================================>]
verify: Service converged
```
This will pull the ubuntu image and run 'sleep 3600' in one container.

### 3. Verify that the service has been created in the Swarm cluster.
```
snow@swarm01:~$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                        PORTS
8o9bicf4mkcp        sleep_app           replicated          1/1                 alpine:latest
```
If you have previous experiences with Docker, it may not seem that we have done anything very differently than just running a docker run. The key difference is that the container has been scheduled on a swarm cluster.

### 4. Scale the application
Imagine a situation were this particular application is under high demand. Docker Swarm allows to re-scale and re-balance the service across the three swarm nodes.
In the following example we will create 9 replicas of the example application.
```
snow@swarm01:~$ docker service update --replicas 9 sleep_app
sleep_app
overall progress: 9 out of 9 tasks
1/9: running   [==================================================>]
2/9: running   [==================================================>]
3/9: running   [==================================================>]
4/9: running   [==================================================>]
5/9: running   [==================================================>]
6/9: running   [==================================================>]
7/9: running   [==================================================>]
8/9: running   [==================================================>]
9/9: running   [==================================================>]
verify: Service converged
```
The new replicas of the application will be scheduled evenly across the Swarm nodes.
```
snow@swarm01:~$ docker service ps sleep_app
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
zgmceedsgj3l        sleep_app.1         alpine:latest       swarm03             Running             Running about a minute ago
m12an8ab0gx1        sleep_app.2         alpine:latest       swarm03             Running             Running 39 seconds ago
n1f8t2scpaqo        sleep_app.3         alpine:latest       swarm02             Running             Running 40 seconds ago
f0leytx1fj3i        sleep_app.4         alpine:latest       swarm01             Running             Running 35 seconds ago
add5r8ik6npz        sleep_app.5         alpine:latest       swarm03             Running             Running 40 seconds ago
45md2xfryhqi        sleep_app.6         alpine:latest       swarm02             Running             Running 39 seconds ago
26vn4t7cyuuo        sleep_app.7         alpine:latest       swarm01             Running             Running 35 seconds ago
rtmfau8n152p        sleep_app.8         alpine:latest       swarm02             Running             Running 39 seconds ago
3o9nev8wwtu6        sleep_app.9         alpine:latest       swarm01             Running             Running 36 seconds ago
```

### 5. Shrink the service
Docker Swarm also allows running the inverse operation. The following example will reduce the number of replicas to 3.
```
snow@swarm01:~$ docker service update --replicas 3 sleep_app
```
You can see how Docker Swarm reduces the replicas with the following command:
```
snow@swarm01:~$ watch docker service ps sleep_app
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
zgmceedsgj3l        sleep_app.1         alpine:latest       swarm03             Running             Running 8 minutes ago
n1f8t2scpaqo        sleep_app.3         alpine:latest       swarm02             Running             Running 6 minutes ago
f0leytx1fj3i        sleep_app.4         alpine:latest       swarm01             Running             Running 6 minutes ago
```
### 6. Reschedule the containers after a node failure or node draining.
The following section will illustrate what happen when a node is drained or faulty.
Take a look at the status of your nodes again by running ``docker node ls``.
```
snow@swarm01:~$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
hxakgodvxtz9ynsc0nniyz7ol *   swarm01             Ready               Active              Leader              18.03.1-ce
t3z5ru9ssu20b7a9i9bj4p5sl     swarm02             Ready               Active                                  18.03.1-ce
o4vbamp797i2yrvo7anqlgd8y     swarm03             Ready               Active                                  18.03.1-ce
```
We will simulate a node failure with the command ``snow destroy swarm02``
We can check the status of the cluster with the following command:
```
snow@swarm01:~$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
hxakgodvxtz9ynsc0nniyz7ol *   swarm01             Ready               Active              Leader              18.03.1-ce
t3z5ru9ssu20b7a9i9bj4p5sl     swarm02             Down                Active                                  18.03.1-ce
o4vbamp797i2yrvo7anqlgd8y     swarm03             Ready               Active                                  18.03.1-ce
```
The following command will show how the services have been re-balanced and re-scheduled:
```
snow@swarm01:~$ docker service ps sleep_app
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
zgmceedsgj3l        sleep_app.1         alpine:latest       swarm03             Running             Running 14 minutes ago
1yv65qqonvju        sleep_app.3         alpine:latest       swarm03             Running             Running 2 minutes ago
n1f8t2scpaqo         \_ sleep_app.3     alpine:latest       swarm02             Shutdown            Running 12 minutes ago
f0leytx1fj3i        sleep_app.4         alpine:latest       swarm01             Running             Running 12 minutes ago
```
Finally, we can drain the Docker Swarm manager node (swarm03), which will degrade the cluster to only one node (swarm01).
Using the command ``docker node update --availability drain <NODEID>``. Where the <NODEID> is provided by the command ``docker node ls``.
```
snow@swarm01:~$ docker node update --availability drain o4vbamp797i2yrvo7anqlgd8y
```
Check the status of the nodes
```
snow@swarm01:~$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
hxakgodvxtz9ynsc0nniyz7ol *   swarm01             Ready               Drain               Leader              18.03.1-ce
t3z5ru9ssu20b7a9i9bj4p5sl     swarm02             Down                Active                                  18.03.1-ce
o4vbamp797i2yrvo7anqlgd8y     swarm03             Ready               Active                                  18.03.1-ce
```
Finally, as expected, all the services have been migrated to the node swarm03 which also assumed the manager role.
```
snow@swarm01:~$ docker service ps sleep_app
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
zgmceedsgj3l        sleep_app.1         alpine:latest       swarm03             Running             Running 20 minutes ago
1yv65qqonvju        sleep_app.3         alpine:latest       swarm03             Running             Running 8 minutes ago
n1f8t2scpaqo         \_ sleep_app.3     alpine:latest       swarm02             Shutdown            Running 19 minutes ago
wu8hj9j9e9uh        sleep_app.4         alpine:latest       swarm03             Running             Running 2 minutes ago
f0leytx1fj3i         \_ sleep_app.4     alpine:latest       swarm01             Shutdown            Shutdown 2 minutes ago
```
### 7. Cleaning Up
The following example will remove the service.
```
docker service rm sleep_app
```
## Service Orchestration
The following example represents much better the benefits of adopting this technology.

### Defining a stack of services
Docker Swarm allows to deploy a complete application stack to the swarm. The deploy command accepts a stack description in the form of a Compose file.

In the container folder there is a file called monitoring-stack.yml which contains an example of a complete monitoring stack including a ElasticSearch cluster, kibana, InfluxDB, grafana, etc.

Download this file to your swarm01 and execute the following command to orchestrate the monitoring stack example:
```
snow@swarm01:~$ docker stack deploy -c monitoring-stack.yml monitor
Creating service monitor_cadvisor
Creating service monitor_elasticsearch
Creating service monitor_elasticsearch2
Creating service monitor_elasticsearch3
Creating service monitor_kibana
Creating service monitor_headPlugin
Creating service monitor_influxdb
Creating service monitor_grafana
```
Now you can check the status of each service with the command:
```
snow@swarm01:~$ docker stack services monitor
ID                  NAME                     MODE                REPLICAS            IMAGE                                                 PORTS
058pildrvl8i        monitor_elasticsearch3   replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch:6.2.4
4gbk7a7zoqz8        monitor_kibana           replicated          0/1                 docker.elastic.co/kibana/kibana:6.3.2                 *:5601->5601/tcp
aqsu06woh4wf        monitor_headPlugin       replicated          1/1                 mobz/elasticsearch-head:5                             *:9100->9100/tcp
bh0r4hsbx3s3        monitor_grafana          replicated          1/1                 grafana/grafana:latest                                *:80->3000/tcp
h0h8hhvwzd19        monitor_elasticsearch2   replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch:6.2.4
juwnpqap4q1o        monitor_influxdb         replicated          1/1                 influxdb:latest
m0isumy3f1fe        monitor_elasticsearch    replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch:6.2.4   *:9200->9200/tcp
wdz7qvp39qwz        monitor_cadvisor         global              2/2                 google/cadvisor:latest
```

## More information:
* [Admin guide](https://docs.docker.com/engine/swarm/admin_guide/).
* [Rolling update](https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/)
