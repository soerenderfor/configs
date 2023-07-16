#!/bin/bash
#################################################################################
# Installation scripts
# This script create new grafana config
#
# Folder: tweaks
# Filename: grafana_confing.sh
#
# By Soeren Kahr
# Contact soeren@derfor.dk
#################################################################################
#

# Create new custom grafana config
sed -i 's/;http_port = 3000/http_port = 3240/' "/etc/grafana/grafana.ini"
sed -i 's/;allow_sign_up = true/allow_sign_up = false/' "/etc/grafana/grafana.ini"
sed -i 's/;allow_org_create = true/allow_org_create = false/' "/etc/grafana/grafana.ini"
sed -i 's/;auto_assign_org = true/auto_assign_org = true/' "/etc/grafana/grafana.ini"
sed -i 's/;allow_embedding = false/allow_embedding = true/' "/etc/grafana/grafana.ini"
sed -i 's/;enabled = true/enabled = true/' "/etc/grafana/grafana.ini"

# Restart grafana-server
systemctl restart grafana-server

# Done
echo "Create grafana config.. Done..!"