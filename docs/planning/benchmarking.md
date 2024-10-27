# Benchmarking Graphistry for Capacity Planning

## Introduction

Deploying Graphistry Enterprise software efficiently requires understanding the hardware resources needed to meet varying usage patterns. This document outlines the benchmarking process to determine optimal configurations based on different scales of user load and data volumes. Proper benchmarking ensures that your system can handle peak usage without compromising functionality, performance, or the user experience.

Benchmarking helps identify the high-watermarks of system resources like GPU memory, CPU, system RAM, and disk space. By simulating different usage scenarios, you can:
- **Ensure System Stability:** Prevent crashes or slowdowns during peak usage.
- **Optimize Performance:** Maintain smooth and responsive user experiences.
- **Plan for Scalability:** Make informed decisions about scaling up hardware as usage grows.
- **Manage costs:** Right-size footprint for current and upcoming workloads and  negotiate longterm hardware commitments.

Additional details can be found here:
- [Graphistry Admin Guide - Telemetry](../tools/telemetry.md)
- [Graphistry Admin Guide - Planning a Graphistry Deployment](deployment-planning.md)
- [Graphistry Admin Guide - Recommended Deployment Configurations: Client, Server Software, Server Hardware](hardware-software.md)

## Intuitions

- **Graphs are in-GPU-memory during use** and get moved to CPU memory and disk when not used, so it is key to track graph size (nodes, edges, attributes) and concurrent user/task load is key.
- **During layout, graphs stream to the browser**, consuming bandwidth proportional to the number of nodes in the graph.
- **Balance GPU utilization to CPU utilization**, which varies by workload.
- **Some workloads are bursty**, such as data science power users loading large visualizations, loading large files for preprocessing, or running large AI models.
- **Some workloads are best managed by physical isolation via multiple GPUs or even servers**, e.g., separating steadier & operational web dashboard users from data science power users.

## Benchmarking Process

### Step 1: Define Use Case Scenarios

Choose the different use cases to capture system metrics at scale. Examples include:
- GFQL/ETL workloads
- Dashboard visualizations
- AI model training

### Step 2: Define Utilization Pattern Scenarios

- **Scaling Up Users:** Increase the number of concurrent users accessing the system.
- **Scaling Up Data Volumes:** Increase the size and complexity of data sets processed by the system. This may mean node or edge count, node or edge attribute size (especially strings).
- **Scaling Up Use Cases:** When hybrid use cases are expected to run concurrently, you may want to test how they interact. For example, check large data science workloads running in parallel with many small graph visualization workloads. Or, when running GFQL queries, how queries on a large graph interact with many queries on medium graphs.
- **Scaling Up Both Users and Data Volumes:** Combine both user and data scaling to stress-test the system under maximum load. You may want to separately consider concurrent user loads where all users are active vs. where some users are actively bursting while others are passively idling.

### Step 3: Set Up Benchmarking Environment

- **Hardware Configuration:** Start with a baseline hardware setup. If possible, using the largest sized servers available will allow for consistent scaling of the workload. It is possible to scale up the size of the server as usage and data volume increases, but this might create skew in the performance tests and take longer.
- **Software Configuration:** Deploy Graphistry Enterprise with default configurations and adjust configuration settings as needed.
- **Benchmarking Tools:** Graphistry provides tools to help capture these metrics both as bash scripts as well as OpenTelemetry and associated dashboards. You may also find basic htop (CPU/RAM), iftop (network), and nvidia-smi (GPU) get you far.
  - Open Telemetry Traces: Utilize telemetry traces to gain deeper insights into system behavior and performance bottlenecks. Graphistry supports [OpenTelemetry](../tools/telemetry.md), enabling comprehensive performance monitoring and analysis.
  - Bash Script: [system-metrics-to-csv.sh](../debugging/system-metrics-to-csv.sh) is also provided if open telemetry is not enabled to assist with capturing metrics for benchmarking.
   
### Step 4: Conduct Benchmark Tests

- **GPU Memory:** Measure the memory usage during peak graphical processing loads. Monitor for bottlenecks and optimize GPU resources.
- **CPU Usage:** Track CPU utilization under different loads. Ensure the CPU can handle peak processing demands without significant performance drops.
- **System RAM:** Monitor RAM usage to ensure there is enough memory for all running processes, especially during data-intensive operations.
- **Disk Space:** Measure the disk I/O and storage usage.
- **Network Bandwidth:** Check peak network utilization during high concurrent user load of streaming visualizations or other network-intensive tasks.

### Step 5: Analyze Results

- **Performance Metrics:** Collect data on system performance, including response times, throughput, and resource utilization.
- **Identify Bottlenecks:** Determine which system components are limiting performance and would improve from additional resources.
- **Optimize Configurations:** Adjust hardware and software settings based on findings to achieve optimal utilization and cost/performance.

## Summary 

Properly sizing hardware for Graphistry Enterprise software ensures robust performance and scalability. By following this benchmarking process and utilizing the recommended configurations, you can optimize your system to handle varying loads and data volumes effectively. Benchmarking is a data-driven approach that helps maintain system stability, improve user experience, and plan for future growth.

Graphistry can assist in this process and also provide architectural recommendations for the various use cases.
