#!/bin/bash

# Assign the first argument to GPU_MODEL_IDENTIFIER
GPU_MODEL_IDENTIFIER="1060"

# Find the bus IDs of the GPUs using lspci
BUS_IDS=$(lspci | grep "$GPU_MODEL_IDENTIFIER" | awk '{print $1}')

# Check if any BUS_IDs are found
if [ -z "$BUS_IDS" ]; then
    echo "No GPUs found with identifier: $GPU_MODEL_IDENTIFIER"
    exit 1
fi

# Define the periodic time interval
PERIODIC_TIME=20 # seconds

# Define the query parameters
QUERY_PARAMS1=""
QUERY_PARAMS2=""
QUERY_PARAMS3=""

# Define the output format
FORMAT1=""
FORMAT2=""

# Define the log files
LOG_FILE1="network_status.log"
LOG_FILE2="ports.txt"
LOG_FILE3="links.txt"

# Function to monitor a single GPU
monitor_gpu() {
	local BUS_ID=$1
	local QUERY_PARAMS1=$2
	local QUERY_PARAMS2=$3
	local QUERY_PARAMS3=$4
	local FORMAT=$5
	local LOG_FILE1=$6
	local LOG_FILE2=$7
	local LOG_FILE3=$8
	local PERIODIC_TIME=$9

	HOST=$(hostname)
	hl-smi -n ports -i 0000:$BUS_ID > $LOG_FILE2
	hl-smi -n link -i 0000:$BUS_ID > $LOG_FILE3

	ports_file=$LOG_FILE2
	links_file=$LOG_FILE3

	# Create associative arrays to map ports to their statuses
	declare -A data_map
	declare -A links_map

	# Read the data file and populate the data_map
	while IFS= read -r line; do
		port=$(echo "$line" | awk '{print $2}' | tr -d ':')
		status=$(echo "$line" | awk '{print $3}')
		data_map["$port"]="$status"
	done < "$ports_file"

	while IFS= read -r line; do
		port=$(echo "$line" | awk '{print $2}' | tr -d ':')
		status=$(echo "$line" | awk '{print $3}')
		links_map["$port"]="$status"
	done < "$links_file"

	# Combine the data and sort by port index
	for port in "${!data_map[@]}"; do
		data_status=${data_map[$port]}
		links_status=${links_map[$port]:-NA}  # Default to DOWN if not found in links_map
		printf "port %2d : %-10s %-10s %-10s %-10s\n" "$port" "$data_status" "$links_status" "$HOST" "0000:$BUS_ID"
	done | sort -k2,2n
	rm -rf $LOG_FILE2 $LOG_FILE3

}

# Export the function so it can be used by parallel
export -f monitor_gpu

# Run the monitoring loop for each GPU in parallel
echo "$BUS_IDS" | xargs -I {} -n 1 -P 1 bash -c 'monitor_gpu "{}" "$@"' _ "$QUERY_PARAMS1" "$QUERY_PARAMS2" "$QUERY_PARAMS3" "$FORMAT2" "$LOG_FILE1" "$LOG_FILE2" "$LOG_FILE3" "$PERIODIC_TIME"

data=$(ip -br -c addr | grep oam | grep -i down)
echo  "$(hostname): $data"
