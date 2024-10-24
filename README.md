# gpu-workloads

ping me at: saidulu.lakumalla@intel.com for help with the scripts.

Two different scripts are listed here. first script is to monitor the GPU data and second script is to capture the network data across the cluster.

1. clone the scripts
   - git clone https://github.com/slakumalla-intel/monitor-gpus.git
   - cd monitor-gpus; chmod +x *.sh

2. Monitor GPUs
   - open the file monitor_gaudi3.sh and change the desired time period to collect the data
   - run the test as:
       ./monitor_gaudi3.sh
       ctrl+c to exit after your test has completed

   - creates 3 output files in csv format
       - gpu_monitor_basiclog.csv : captures the power, temperature, utilization, memory related data 
       - gpu_monitor_ecclog.csv   : captures the ECC error data
       - gpu_monitor_pcielog.csv  : captures the PCIe link speed related data

3. Network ports and data monitoring
   we can capture the data either on the local or across the cluster.
      -Local node :
	 a. To capture the local network data and check if any ports are in the down state
	      ./g3_get_node_port_status.sh | grep -i down

	 b. Cluster nodes data:
	      - open the hosts.txt file and update with the list of intrested nodes
              - setup the passwordless network access to the cluster nodes 
		   ./pass_setup.sh <username> 
		        ex: ./pass_setup.sh slakumal
			Enter your password when prompted during the execution of this script

	       - capture the network port status and stats data across cluster
		   ./cluster_status.sh <username> 
			cat network_status.log | grep -i down
	  c. Output data files to debug:
               - network_external_link_stats.log : captures gaudi externel NIC stats ( across all external ports of nodes listed in hosts.txt)
               - network_internal_link_stats.log : captures gaudi internal port stats ( acorss all internal ports of nodes listed in hosts.txts)
               - network_port_status.log         : captures  gaudi internal and expernal port status ( acorss all ports of nodes listed in the hosts.txt)
