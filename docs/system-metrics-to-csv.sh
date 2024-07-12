#!/bin/bash
#
#
# system-metrics-to-csv.sh:  This script is provided to capture system metrics to assist with benchmarking various workloads. A CSV file is produced
#                               with various metrics at a certain interval.
#
# The metrics that the script collects are as follows: CPU usage, system memory usage, total system ram used, GPU memory usage, and disk utilization.
#
# CSV column headers: "Timestamp,CPU Usage (%),Memory Usage (%),Total RAM Used (MiB),GPU Memory Usage (MiB)$disk_headers"
#
#
# Environment variables to override defaults:
#
#   METRICS_FILENAME -  Path to the CSV file where metrics are stored
#	    default: system-metrics-${DATETIME}.csv
#
#   TIMEOUT_SECS - Timeout in seconds after which the script should stop
#	    default: stop after 1 hour (3600 seconds)
#
#   INTERVAL_SECS - Interval between measurements in seconds
#	    default to 1 sec intervals
#
#
#  USAGE:
#         ./system-metrics.sh  - run with defaults
#
#         METRICS_FILENAME="my-metric-file.csv" TIMEOUT_SECS=900 INTERVAL_SECS=2 ./system-metrics-to-csv.sh  - use this method to override default parameters
#
#


DATETIME=$(date "+%Y.%m.%d-%H.%M.%S")

# Path to the CSV file where metrics are stored
output_file=${METRICS_FILENAME:-"system-metrics-${DATETIME}.csv"}

# Timeout in seconds after which the script should stop
timeout=${TIMEOUT_SECS:-3600} # default: stop after 1 hour

# Interval between measurements in seconds
interval=${INTERVAL_SECS:-5}  # default to 5 sec interval

# Start time of the script
start_time=$(date +%s)

echo "running system-metrics-to-csv.sh"
echo
echo "        Started at:       ${DATETIME}"
echo "        METRICS_FILENAME: ${METRICS_FILENAME}"
echo "        TIMEOUT_SECS:     ${TIMEOUT_SECS}"
echo "        INTERVAL_SECS:    ${INTERVAL_SECS}"
echo

# Discover all physical disks (mounted file systems) and prepare headers for them
disk_headers=$(df -h | grep '^/dev' | awk '{print $1}' | awk -F'/' '{print $(NF)}' | awk '{print ",% Used (" $1 ")"}' | tr -d '\n')
header="Timestamp,CPU Usage (%),Memory Usage (%),Total RAM Used (MiB),GPU Memory Usage (MiB)$disk_headers"

# Check if the output file exists; if not, create it and write the header
if [ ! -f "$output_file" ]; then
    echo "$header" > "$output_file"
fi

echo -ne "Elapsed time: ${elapsed} seconds\r"

while true; do
    # Check elapsed time to decide if we should stop
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    echo -ne "Elapsed time: ${elapsed_time} seconds\r"

    if [ $elapsed_time -ge $timeout ]; then
        echo "Timeout reached: $timeout seconds"
        break
    fi

    # Get the current date and time as the timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Capture CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Capture memory usage
    memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

    # Capture total used RAM in MiB
    total_ram_used=$(free | grep Mem | awk '{print $3/1024}')

    # Capture GPU memory usage
    gpu_memory_usage=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)

    # Prepare to capture disk usage
    disk_usage_data=""
    for disk in $(df -h | grep '^/dev' | awk '{print $1}'); do
        disk_usage=$(df -h | grep "^$disk" | awk '{print $5}')
        disk_usage_data="$disk_usage_data,$disk_usage"
    done

    # Write the data to the CSV file
    echo "${timestamp},${cpu_usage},${memory_usage},${total_ram_used},${gpu_memory_usage}${disk_usage_data}" >> "$output_file"

    # Sleep for the specified interval
    sleep $interval
done

