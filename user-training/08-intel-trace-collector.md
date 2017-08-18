# Hands-On 08: Intel Trace Collector
In this hands-on, we are going to collect statistics and key metrics with Intel MPI and Intel Trace Collector. If your application is already compiled with Intel MPI, we strongly suggest you to use your own code using a short test.

*Estimated time : 15 minutes*

## Requirements
Cluster account.
Laptop with SSH client.

## ToDo
Open an interactive session from the login node:

```
interactive
```

## Collect MPI traces with Intel Trace Collector

In the hands-on-08 folder you will find two submit script examples to collect MPI traces based on example code:
* [```Intel-Trace-Analyser-and-Collector-2017.sh```](examples/mpi_tuning/Intel-Trace-Analyser-and-Collector-2017.sh)                           <-- for non-instrumented code
* [```Intel-Trace-Analyser-and-Collector-instrumented-2017.sh```](examples/mpi_tuning/Intel-Trace-Analyser-and-Collector-instrumented-2017.sh) <-- for instrumented code

Choose one of them, explore and modify the content of the script and submit the job. Please, note that you will take more benefits of this training if you use your own code. The test should be no longer than 15 minutes.

If you don’t have a code ready, you can use the example located in: ```$HOME/snow-labs/user-training/examples/Cardiac_demo``` which is a hybrid MPI/OpenMP application.

In order to build and instrument the code you will need to load the following environment:

```
ml intel/2017a
ml VTune/2017_update2
ml itac/2017.2.028
source itacvars.sh impi5
```

Move to the folder Cardiac_demo and build the example code with and without instrumentation:

### Non-instrumented
```
cd $HOME/snow-labs/user-training/examples/Cardiac_demo
mkdir build_non-instrumented
cd build_non-instrumented
mpiicpc ../heart_demo.cpp ../luo_rudy_1991.cpp ../rcm.cpp ../mesh.cpp -g \
        -o heart_demo -O3 -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 -qopenmp -parallel-source-info=2
```

### Instrumented
```
cd $HOME/snow-labs/user-training/examples/Cardiac_demo
mkdir build_instrumented
cd build_instrumented
mpiicpc ../heart_demo.cpp ../luo_rudy_1991.cpp ../rcm.cpp ../mesh.cpp -tcollect -g \
        -o heart_demo -O3 -std=c++11 -qopenmp -parallel-source-info=2 \
        -D_GLIBCXX_USE_CXX11_ABI=0 $VT_ADD_LIBS
```

Using the [```scalability_test.sh```](examples/mpi_tuning/scalability_test.sh) and the following command lines, you should be able to find the most optimal combination of processes and threads to run with. 

```
cd $HOME/snow-labs/user-training/examples/mpi_tuning
for i in 1 4 12; do sbatch --ntasks=$((48/$i)) --cpus-per-task=$i scalability_test.sh ; done
```

You can review the benchmark results here: ```$HOME/snow-labs/user-training/OUT/benchmark-results.txt```

Once you get the best result, submit a job based on those scripts ```Intel-Trace-Analyser-and-Collector-instrumented-*.sh``` in order to collect the MPI traces.

```
cd $HOME/snow-labs/user-training/examples/mpi_tuning
sbatch --ntasks=XX --cpus-per-task=YY Intel-Trace-Analyser-and-Collector-2017.sh
sbatch --ntasks=XX --cpus-per-task=YY Intel-Trace-Analyser-and-Collector-instrumented-2017.sh
```
Where XX are the number of MPI tasks and YY are the number of OpenMP threads which delivered the best performance.

Once the job are done, you will find the traces collected in: ```$HOME/snow-labs/user-training/OUT/```

