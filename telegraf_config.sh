#!/bin/bash
#################################################################################
# Installation scripts
# This script create telegraf config
#
# Folder: configs
# File name: telegraf_config.sh
#
# By Soeren Kahr
# Contact soeren@derfor.dk
#################################################################################
#

# Rename the default configuration file
mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.default

# Create a new other configuration
cat > /etc/telegraf/telegraf.conf <<EOF
# Configuration for telegraf agent
[agent]
	hostname = "Monitoring"
	flush_interval = "15s"
	interval = "15s"

###############################################################################
# OUTPUT PLUGINS
###############################################################################

# Configuration for sending metrics to InfluxDB
[[outputs.influxdb]]
	## The full HTTP or UDP URL for your InfluxDB instance.
	##
	## Multiple URLs can be specified for a single cluster, only ONE of the
	## urls will be written to each interval.
	urls = [ "https://localhost:8086" ]

	## The target database for metrics; will be created as needed.
	## For UDP url endpoint database needs to be configured on server side.
	database = "telegrafdb"

	## HTTP Basic Auth
	username = "telegraf"
	password = "myP@ssw0rd"


###############################################################################
# PROCESSOR PLUGINS
###############################################################################


###############################################################################
# AGGREGATOR PLUGINS
###############################################################################


###############################################################################
# INPUT PLUGINS
###############################################################################

# Read metrics about cpu usage
[[inputs.cpu]]
	## Whether to report per-cpu stats or not
	percpu = true
	## Whether to report total system cpu stats or not
	totalcpu = true
	## If true, collect raw CPU time metrics
	collect_cpu_time = false
	## If true, compute and report the sum of all non-idle CPU states
	report_active = false

# Read metrics about disk usage by mount point
[[inputs.disk]]
	## By default stats will be gathered for all mount points.
	## Set mount_points will restrict the stats to only the specified mount points.
	# mount_points = ["/"]

	## Ignore mount points by filesystem type.
	ignore_fs = ["tmpfs", "devtmpfs", "devfs"]

# Get kernel statistics from /proc/stat
[[inputs.kernel]]

# Read metrics about memory usage
[[inputs.mem]]

# Get the number of processes and group them by status
[[inputs.processes]]

# Read metrics about swap memory usage
[[inputs.swap]]

# Read metrics about system load & uptime
[[inputs.system]]
	## Uncomment to remove deprecated metrics.
	# fielddrop = ["uptime_format"]

# Read metrics about network interface usage
[[inputs.net]]
	## By default, telegraf gathers stats from any up interface (excluding loopback)
	## Setting interfaces will tell it to gather these explicit interfaces,
	## regardless of status.
	##
	# interfaces = ["eth0"]
	##
	## On linux systems telegraf also collects protocol stats.
	## Setting ignore_protocol_stats to true will skip reporting of protocol metrics.
	##
	# ignore_protocol_stats = false

# Read TCP metrics such as established, time wait and sockets counts.
[[inputs.netstat]]

# Read metrics about IO
[[inputs.io]]

# # Monitor APC UPSes connected to apcupsd
#[[inputs.apcupsd]]
        ## A list of running apcupsd server to connect to.
        ## If not provided will default to tcp://127.0.0.1:3551
        #servers = ["tcp://127.0.0.1:3551"]
        ##
        ## Timeout for dialing server.
        #timeout = "5s"


###############################################################################
# SERVICE INPUT PLUGINS
###############################################################################
EOF

# Restart telegraf service
systemctl restart telegraf

# Done
echo "Create telegraf config.. Done..!"
