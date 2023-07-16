#!/bin/bash
#################################################################################
# Installation scripts
# This script create loki-local-config
#
# Folder: config
# File name: loki-local-config.sh
#
# By Soeren Kahr
# Contact soeren@derfor.dk
#################################################################################
#

# Create loki-local-config.yaml
cat > /etc/promtail/loki-local-config.yaml <<EOF
auth_enabled: false 
server: 
  http_listen_port: 3100 
ingester: 
  lifecycler: 
    address: 127.0.0.1 
    ring: 
      kvstore: 
        store: inmemory 
      replication_factor: 1 
    final_sleep: 0s 
  chunk_idle_period: 5m 
  chunk_retain_period: 30s 
schema_config: 
  configs: 
  - from: 2020-05-15 
    store: boltdb 
    object_store: filesystem 
    schema: v11 
    index: 
      prefix: index_ 
      period: 168h 
storage_config: 
  boltdb: 
    directory: /tmp/loki/index 
  filesystem: 
    directory: /tmp/loki/chunks 
limits_config: 
  enforce_metric_name: false 
  reject_old_samples: true 
  reject_old_samples_max_age: 168h 
  max_entries_limit_per_query: 500000 
# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration 
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/ 
# 
# Statistics help us better understand how Loki is used, and they show us performance 
# levels for most users. This helps us prioritize features and documentation. 
# For more information on what's sent, look at 
# https://github.com/grafana/loki/blob/main/pkg/usagestats/stats.go 
# Refer to the buildReport method to see what goes into a report. 
# 
# If you would like to disable reporting, uncomment the following lines: 
#analytics: 
#  reporting_enabled: false
EOF

# Done
echo "Create loki-local-config.yaml.. Done..!"