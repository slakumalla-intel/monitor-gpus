#!/bin/bash

DEVICE_ID=1020 # Gaudi device ID
TOTAL_CORES=72

# Number of Gaudi devices per host
NUM_DEVICES=8

# Calculate threads per device
THREADS_PER_DEVICE=$((TOTAL_CORES / NUM_DEVICES))

# Get the list of PCIe devices with the specified device ID
PCI_DEVICES=$(lspci | grep "$DEVICE_ID" | awk '{print $1}')
echo $PCI_DEVICES

# Check if any devices were found
if [ -z "$PCI_DEVICES" ]; then
  echo "No PCIe devices found with device ID $DEVICE_ID"
  exit 1
fi

# Initialize CPU core start index
CPU_START=0

export PYTHON=/usr/bin/python3.10
export __python_cmd=$PYTHON

# Function to run hl_qual for a given BUS ID and CPU mask
run_hl_qual() {
  local BUS_ID=$1
  local CPU_MASK=$2
  echo "Running hl_qual for device at BUS ID: $BUS_ID with CPU mask: $CPU_MASK"
  cd /opt/habanalabs/qual/gaudi2/bin
  taskset $CPU_MASK ./hl_qual -gaudi2 -c all -rmod parallel -t 20 -p -b -gen gen5
  echo "Completed hl_qual for BUS ID $BUS_ID"
  echo "--------------------------------------"
}

# Loop through each PCIe device and run hl_qual in parallel
for BUS_ID in $PCI_DEVICES; do
  # Calculate CPU core mask for the current device
  CPU_MASK=$(printf 0x%x $(( (1 << THREADS_PER_DEVICE) - 1 << CPU_START )))

  # Run hl_qual using taskset to bind to specific CPU cores in the background
  run_hl_qual $BUS_ID $CPU_MASK &

  # Update CPU start index for the next device
  CPU_START=$((CPU_START + THREADS_PER_DEVICE))
done

# Wait for all background processes to complete
wait

echo "All hl_qual tests completed."
