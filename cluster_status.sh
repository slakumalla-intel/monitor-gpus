#!/bin/bash

HOSTS_FILE="hosts.txt"
LOCAL_SCRIPT_1="g3_get_node_port_status.sh"
LOCAL_SCRIPT_2="g3_internal_ports_stats.sh"
LOCAL_SCRIPT_3="g3_external_port_stats.sh"
OUTPUT_FILE_1="network_port_status.log"
OUTPUT_FILE_2="network_internal_link_stats.log"
OUTPUT_FILE_3="network_external_link_stats.log"
REMOTE_SCRIPT="/tmp/get_network.sh"

# Function to execute SSH command
ssh_command() {
    local host=$1
    local username=$2
    local localscript=$3

    # Copy the local script to the remote host
    scp "$localscript" "$username@$host:$REMOTE_SCRIPT"
    if [ $? -ne 0 ]; then
        echo "$host: Connection failed (SCP error)"
        return
    fi

    # Execute the script on the remote host
    ssh "$username@$host" "chmod +x $REMOTE_SCRIPT && bash $REMOTE_SCRIPT" > output.log 2> error.log
    if [ $? -ne 0 ]; then
        echo "$host: Connection failed (SSH error)"
        return
    fi

    # Capture the output
    local output=$(cat output.log)
    local error=$(cat error.log)

    if [ -n "$error" ]; then
        echo "$host: Error: $error"
    else
        echo "$host: $output"
    fi
}

# Main function
main() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <username>"
        exit 1
    fi

    local username=$1

    # Check if the hosts file exists
    if [ ! -f "$HOSTS_FILE" ]; then
        echo "Hosts file not found: $HOSTS_FILE"
        exit 1
    fi

    # Check if the local script exists
    if [ ! -f "$LOCAL_SCRIPT_1" ]; then
        echo "Local script not found: $LOCAL_SCRIPT_1"
        exit 1
    fi

    # Read the list of hosts
    local hosts=()
    while IFS= read -r line; do
        [ -n "$line" ] && hosts+=("$line")
    done < "$HOSTS_FILE"

    # Open the output file
    > "$OUTPUT_FILE_1"
    for host in "${hosts[@]}"; do
        result=$(ssh_command "$host" "$username" "$LOCAL_SCRIPT_1")
        echo "$result"
        echo "$result" >> "$OUTPUT_FILE_1"
    done


    > "$OUTPUT_FILE_2"
    for host in "${hosts[@]}"; do
        result=$(ssh_command "$host" "$username" "$LOCAL_SCRIPT_2")
        .echo "$result"
        echo "$result" >> "$OUTPUT_FILE_2"
    done

    > "$OUTPUT_FILE_3"
    for host in "${hosts[@]}"; do
        result=$(ssh_command "$host" "$username" "$LOCAL_SCRIPT_3")
        echo "$result"
        echo "$result" >> "$OUTPUT_FILE_3"
    done


    #echo "Hostnames captured in $OUTPUT_FILE"
    rm output.log
    echo "********** List of ports DOWN ***********"
    cat $OUTPUT_FILE_1 | grep -i DOWN
    echo "*****************************************"

    echo "********** List of internal ports flapping, check the fault counters **"
    cat $OUTPUT_FILE_2 | grep -i "pcs"
    echo "*****************************************"

    echo "********** List of external  ports flapping, check the fault counters **"
    cat $OUTPUT_FILE_3 | grep -i "pcs"
    echo "*****************************************"
}

# Execute the main function
main "$@"
