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
# Hands-On 10: MPI Runtime Tuning

In this hands-on, we are going to potential performance improvements by tuning the MPI runtime environment.

*Estimated time : 30 minutes*

## Requirements
* Cluster account.
* Laptop with SSH client.

## ToDo

### Interconnect fabrics tuning

For resilience reasons, Intel MPI library falls back from "dapl" or "shm:dapl" fabric to lower performance fabric if DAPL provider initialization failed.
```
export I_MPI_FALLBACK=disable
export I_MPI_FABRICS=shm:dapl
```
Connectionless Communication Feature (DAPL UD) provides better scalability and reduces memory requirements:

```
export I_MPI_DAPL_UD=enable
export I_MPI_FABRICS=shm:dapl
```
### Process placement and pinning
Data locality improves performance. If the code uses shared memory (i.e. OpenMP), the best choice is to regroup the threads into the same socket.

The shared data should be local to the socket and moreover, the data will potentially stay on the processor's cache.

System processes can interrupt your process running on a core. If your process is not bound to a core or to a socket, it can be moved. In this case, all data for this process has to be moved as wll, and this involves a huge overhead..

MPI communication is faster between processes which are on the same socket. If you know that two tasks perform many communications, you can bind them to the same socket.

Explore the architecture topology with lstopo in an interactive job session or inside a job:

```
interactive
salloc: Pending job allocation 4931
salloc: job 4931 queued and waiting for resources
salloc: job 4931 has been allocated resources
salloc: Granted job allocation 64594931
[ snow@hsw131 ~ ]$ lstopo
Machine (128GB)
  NUMANode L#0 (P#0 64GB)
  NUMANode L#1 (P#1 64GB) + Socket L#0 + L3 L#0 (30MB) + L2 L#0 (256KB) + L1 L#0 (32KB) + Core L#0 + PU L#0 (P#13)
[ snow@hsw131 ~ ]$ lstopo -c
Machine (128GB) cpuset=0x00002000
  NUMANode L#0 (P#0 64GB) cpuset=0x0
  NUMANode L#1 (P#1 64GB) cpuset=0x00002000
    Socket L#0 cpuset=0x00002000
      L3 L#0 (30MB) cpuset=0x00002000
        L2 L#0 (256KB) cpuset=0x00002000
          L1 L#0 (32KB) cpuset=0x00002000
            Core L#0 cpuset=0x00002000
              PU L#0 (P#13) cpuset=0x00002000
```

#### Process Placement with Slurm
* The first distribution method (before the ":") controls the distribution of resources across nodes.
* The optional second distribution method (after the ":") controls the distribution of resources across sockets within a node.

```
-m, --distribution=1st_method:2nd_method
1st_method : <block|cyclic|arbitrary|plane=<options>
2nd_method : [:block|cyclic]
```

### Point-to-point communication

#### Disable dynamic connection mode (on-demand connection establishment)
* enable scalable algorithm for DAPL read progress engine. It offers performance advantage for large (>64) numbers of processes.
* Apply wait mode to oversubscribed jobs. The processes that waits for receiving messages without polling of the fabric(s) can save CPU time.

```
export I_MPI_DYNAMIC_CONNECTION=0
export I_MPI_DAPL_SCALABLE_PROGRESS=1
export I_MPI_WAIT_MODE=enable
```

#### Eager/rendezvous protocol threshold
Intel MPI provides an environment variable which controls high level protocol switch over point. Short message are sent using the eager protocol, larger are sent by using the more memory efficient rendezvous protocol.

```
export I_MPI_EAGER_THRESHOLD = VALUE
```

#### Bypass shmem for intranode communication
This option will turns on RDMA data exchange within single node that may outperform regular shared memory exchange. This is normally happens for large (350kb+) messages.
* shorter messages than or equal in size to the threshold value are transferred using shared memory,
* larger messages through network fabric layer.
* Explore potential benefits of increasing this threshold.
* Default value is ```I_MPI_EAGER_THRESHOLD=256kb```

```
export I_MPI_SHM_BYPASS*=enable
```
#### Bypass cache for intranode communication
Control a message transfer algorithm for shm device: generic copying or cache bypass (using non-temporal store)
* Each case have own threshold pair (read/write in shm queue).
* can be tuned by ```I_MPI_SHM_CACHE_BYPASS_THRESHOLDS```
* Some default thresholds are set to half of L2.
* It's a good practice to start with L1 cache size value.
Suggested Values

```
export I_MPI_SHM_CACHE_BYPASS_THRESHOLDS = VALUE
```

### Collective algorithms
The environment variable ```I_MPI_ADJUST_<opname>``` allows to change the algorithm for the specific collective operation.

Based on the trace analysis, explore what benefits could provide those algorithms in the most rellevant collective operation.
More information in the Intel MPI manual.
Example for ALLREDUCE: ```I_MPI_ADJUST_ALLREDUCE``` value controls MPI_Allreduce algorithm for Intel MPI 5.
* Recursive doubling algorithm
* Rabenseifner's algorithm
* Reduce + Bcast algorithm
* Topology aware Reduce + Bcast algorithm
* Binomial gather + scatter algorithm
* Topology aware binominal gather + scatter algorithm
* Shumilin's ring algorithm
* Ring algorithm
* Knomial algorithm

#### Suggested proceeding
We can test which one yields the best result by testing 9 different allreduce algorithms.
* Focus on the most critical collective operations.
* Run short tests and explore the impact of all the algorithms by changing the following values:
```
OUT=$HOME/test/octopus/allreduce-$SLURM_NTASKS.dat
for i in {1..9}
do
    export I_MPI_ADJUST_ALLREDUCE=$i
    /usr/bin/time -a -o $OUT srun octopus_mpi    
    rm -fr exec profiling.* restart static
done
```
