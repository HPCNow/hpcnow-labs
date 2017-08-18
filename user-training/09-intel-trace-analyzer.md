# Hands-On 09: Intel Trace Analyzer
In this hands-on, we are going to analise the traces collected in the previous hands-on session with Intel Trace Analyzer.

*Estimated time : 30 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

# ToDo
Open an interactive session from the login node:

```
interactive -X11
```

Load the following user environment:

```
ml intel/2017a
ml VTune/2017_update2
ml itac/2017.2.028
source itacvars.sh impi5
```

Move to folder where the traces had been collected and open the trace file with:

```
cd $HOME/snow-labs/user-training/OUT/XXXXXX
traceanalyzer ./heart_demo.single.stf &
```

Where ```XXXXXXX``` is the JobID of the job which collected the traces

Explore the result data analysing:
* Event Timeline 
* Ungroup MPI Functions
* Detect Serialization in Function Profile and Message Profile
* Compare Original Trace File With Idealized Trace File
* Message Profile chart
* Explore Potential issues and suggested sections of the code affected

