# Hands-On 11: Single Task Tuning

In this hands-on, we are going to explore potential tuning oportunities in single tasks by using Intel advisor for vectorization and OpenMP parallelization.
In general, all the codes can take advantage of this exercise, from simple serial applications to complex hybrid MPI+OpenMP applications.

*Estimated time : 2 hours*

## Requirements
* Cluster account.
* Laptop with SSH client.

## ToDo

In this hands-on session we are going to use a simple matrix multiplication example to explain how to identify opportunities to tune single tasks code. Square matrix multiplication involve *n* multiplications and *n−1* additions per element. Since there are *n<sup>2</sup>* elements, the dot product must be computed *n<sup>2</sup>* times. The total number of operations is *n<sup>2</sup>(n+(n−1))=2n<sup>3</sup>−n<sup>2</sup>* which means [computational complexity](https://en.m.wikipedia.org/wiki/Computational_complexity_of_mathematical_operations) of *O(n<sup>3</sup>)* using schoolbook algorithm.

Load the required environment for this hands-on:

```
ml intel/2017a
```

Compile the first serial example ([```serial_mm.c```](examples/single_task_tuning/serial_mm.c)) and run the program: 

```
cd $HOME/snow-labs/user-training/examples/single_task_tuning
icc serial_mm.c -o serial_mm_default
./serial_mm_default
```

The program reports the runtime and also generates a file with the result of the matrix multiplication.
In order to remove noise related with the IO, comment the loop responsible for writing the results into the result.txt file.

Compile it and run it again in order to evaluate a real improvement in the computational component of the code.

```
cd $HOME/snow-labs/user-training/examples/single_task_tuning
icc serial_mm.c -o serial_mm_default
./serial_mm_default
```

The reported runtime is what we are going to use to compare further improvements in the performance and efficiency.

## Auto-Vectorization

Explore potential auto-vectorization opportunities by compiling the code with the following options.

```
icc -O3 -xHost -qopt-report=5 -qopt-report-phase:vec serial_mm.c -o serial_mm_vec 
./serial_mm_vec
```

This generates a file with a report of the attempts of vectorization ```serial_mm.optrpt```.
When the loop gets vectorized, it reports the expected speed-up for that particular loop.
When the loop is not vectorized, it reports the reason. Writting the loops in very specific way helps the compiler to identify those opportunities. Otherwise you can define custom SIMD instructions in the code.

Explore how much improvement your code has achieved with auto-vectorization

```
./serial_mm_vec
```

And compare it with the same optimizations but without vectorization

```
icc -O3 -xHost -qopt-report -qopt-report-phase:vec serial_mm.c -o serial_mm_novec -no-vec
./serial_mm_novec
```

## Auto-parallelization 

Explore potential auto-parallelization opportunities by compiling the code with the following options:

```
icc -parallel -O3 -qopt-report-phase:par -qopt-report=5 serial_mm.c -o serial_mm_openmp
```

This generates a new report file (```serial_mm.optrpt```) with the attemps to parallelize the code with OpenMP. 

The compiler reports some suggestions but as developers of the code we already know that there are better ways to implement OpenMP directives in this simple code.
Compare the suggested OpenMP directives with those available in the file [```openmp_mm.c```](examples/single_task_tuning/openmp_mm.c)

```
icc -qopenmp -O3 -xHost -qopt-report-phase:openmp -qopt-report=5 openmp_mm.c -o openmp_mm_novec -no-vec
```

The report will tell only what we instructed to parallelize. 

Using the [```scalability_test.sh```](examples/single_task_tuning/scalability_test.sh) available in ```$HOME/snow-labs/user-training/examples/single_task_tuning``` and the following command lines, you should be able to find the most optimal number of OpenMP threads to run with. 

```
cd $HOME/snow-labs/user-training/examples/single_task_tuning
for i in 1 2 4 6 8 12; do sbatch --cpus-per-task=$i scalability_test.sh ; done
```

You can review the benchmark results here: $HOME/snow-labs/user-training/OUT/benchmark-results.txt

Finally, combine both levels of parallelism a the same time and submit again the jobs to find the most optimal number of threads:

```
icc -qopenmp -O3 -xHost openmp_mm.c -o openmp_mm
for i in 1 2 4 6 8 12; do sbatch --cpus-per-task=$i scalability_test.sh ; done
```

## Need for more scalability and best practices
As you have noticed, auto-vectorization had improved the performance of the serial code, but the auto-parallelization did not show any gain. You can look for a more efficient [parallel matrix multiplication algorithm](https://en.m.wikipedia.org/wiki/Matrix_multiplication_algorithm#Parallel_and_distributed_algorithms) which reduces the computational complexity and improves the scalability.

Compare the content of [openmp_mm_tuned.c](examples/single_task_tuning/openmp_mm_tuned.c) with your current version and explore the performance improvement by using a more efficient algorithm.

```
icc -qopenmp -O3 -xHost openmp_mm_tuned.c -o openmp_mm
for i in 1 2 4 6 8 12; do sbatch --cpus-per-task=$i scalability_test.sh ; done
```

The most advanced algorithms are usually available in [advanced numerical libraries](https://en.wikipedia.org/wiki/List_of_numerical_libraries) like "[Basic Linear Algebra Subprograms](https://en.wikipedia.org/wiki/Basic_Linear_Algebra_Subprograms)".

These libraries hide the complexity around very common mathematical operations. In this [example](https://software.intel.com/en-us/node/529735), the matrix multiplication is reduced to this call to the dgemm routine:

```
cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
           m, n, k, alpha, A, k, B, n, beta, C, n);
```
