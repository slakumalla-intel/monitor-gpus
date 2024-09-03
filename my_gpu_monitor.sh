#!/bin/bash

# Assign the first argument to GPU_MODEL_IDENTIFIER
GPU_MODEL_IDENTIFIER="1020"

# Find the bus IDs of the GPUs using lspci
BUS_IDS=$(lspci | grep "$GPU_MODEL_IDENTIFIER" | awk '{print $1}')

# Check if any BUS_IDs are found
if [ -z "$BUS_IDS" ]; then
    echo "No GPUs found with identifier: $GPU_MODEL_IDENTIFIER"
    exit 1
fi

# Define the periodic time interval
PERIODIC_TIME=1 # seconds

# Define the query parameters
QUERY_PARAMS1="timestamp,name,bus_id,driver_version,temperature.aip,module_id,utilization.aip,memory.total,memory.free,memory.used,index,serial,uuid,power.draw"
QUERY_PARAMS2="timestamp,name,ecc.errors.uncorrected.aggregate.total,ecc.errors.uncorrected.volatile.total,ecc.errors.corrected.aggregate.total,ecc.errors.corrected.volatile.total,ecc.errors.dram.aggregate.total,ecc.errors.dram-corrected.aggregate.total,ecc.errors.dram.volatile.total,ecc.errors.dram-corrected.volatile.total,ecc.mode.current,ecc.mode.pending"
QUERY_PARAMS3="timestamp,name,stats.violation.power,stats.violation.thermal,clocks.current.soc,clocks.max.soc,clocks.limit.soc,clocks.limit.tpc,pcie.link.gen.max,pcie.link.gen.current,pcie.link.width.max,pcie.link.width.current,pcie.link.speed.max,pcie.link.speed.current"

# Define the output format
FORMAT1="csv"
FORMAT2="csv,noheader"

# Define the log files
LOG_FILE1="gpu_monitor_basiclog.csv"
LOG_FILE2="gpu_monitor_ecclog.csv"
LOG_FILE3="gpu_monitor_pcielog.csv"

# Backup existing log files
mv $LOG_FILE1 $LOG_FILE1".bkup" 2>/dev/null
mv $LOG_FILE2 $LOG_FILE2".bkup" 2>/dev/null
mv $LOG_FILE3 $LOG_FILE3".bkup" 2>/dev/null

# Initial run to create log files with headers
hl-smi --query-aip=$QUERY_PARAMS1 --format=$FORMAT1 >> $LOG_FILE1
hl-smi --query-aip=$QUERY_PARAMS2 --format=$FORMAT1 >> $LOG_FILE2
hl-smi --query-aip=$QUERY_PARAMS3 --format=$FORMAT1 >> $LOG_FILE3

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

    while true; do
    echo "Monitoring GPU with bus ID: $BUS_ID" 
        hl-smi --query-aip=$QUERY_PARAMS1 --format=$FORMAT >> $LOG_FILE1 #TODO busid
        hl-smi --query-aip=$QUERY_PARAMS2 --format=$FORMAT >> $LOG_FILE2
        hl-smi --query-aip=$QUERY_PARAMS3 --format=$FORMAT >> $LOG_FILE3
        sleep $PERIODIC_TIME
    done
}

# Export the function so it can be used by parallel
export -f monitor_gpu

# Run the monitoring loop for each GPU in parallel
echo "$BUS_IDS" | xargs -I {} -n 1 -P 0 bash -c 'monitor_gpu "{}" "$@"' _ "$QUERY_PARAMS1" "$QUERY_PARAMS2" "$QUERY_PARAMS3" "$FORMAT2" "$LOG_FILE1" "$LOG_FILE2" "$LOG_FILE3" "$PERIODIC_TIME"
