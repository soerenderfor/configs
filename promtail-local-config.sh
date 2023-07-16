#!/bin/bash
#################################################################################
# Installation scripts
# This script create promtail-local-config
#
# Folder: config
# File name: promtail-local-config.sh
#
# By Soeren Kahr
# Contact soeren@derfor.dk
#################################################################################
#

# Create promtail-local-config.yaml
cat > /etc/promtail/promtail-local-config.yaml <<EOF
server:  
  http_listen_port: 9080  
  grpc_listen_port: 0  
positions:  
  filename: /tmp/positions.yaml  
clients:  
  - url: http://localhost:3100/loki/api/v1/push 
scrape_configs: 
  - job_name: syslog 
    syslog: 
      listen_address: 0.0.0.0:1514 
      labels: 
        job: syslog 
    relabel_configs: 
      - source_labels: [__syslog_message_hostname] 
        target_label: host 
      - source_labels: [__syslog_message_hostname] 
        target_label: hostname 
      - source_labels: [__syslog_message_severity] 
        target_label: level 
      - source_labels: [__syslog_message_app_name] 
        target_label: application 
      - source_labels: [__syslog_message_facility] 
        target_label: facility 
      - source_labels: [__syslog_connection_hostname] 
        target_label: connection_hostname
EOF

# Done
echo "Create promtail-local-config.yaml.. Done..!"