#!/bin/bash
interfaces=$(ip -br addr | grep oam | awk '{print $1}')
for interface in $interfaces; do
	echo "$(hostname): $interface"
	output=$(ethtool -S $interface  2>&1)
	echo "$output";
done
external_link_status=$(/opt/habanalabs/qual/gaudi3/bin/manage_network_ifs.sh --status | xargs);
echo "external link status for $(hostname): $external_link_status"
