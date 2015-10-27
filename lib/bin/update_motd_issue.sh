#!/bin/bash
# This file is part of the Open AS Communication Gateway.
#
# The Open AS Communication Gateway is free software: you can redistribute it
# and/or modify it under theterms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# The Open AS Communication Gateway is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
# General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with the Open AS Communication Gateway. If not, see http://www.gnu.org/licenses/.

# Vars
OAS_VERSION=$(cat /etc/open-as-cgw/versions | grep main | awk -F'=' '{print $NF}')
OAS_IPADDR=$(ip route get 1 | awk '{print $NF;exit}')
OAS_HOSTNAME=$(hostname)
OAS_SERVICE_STATUS='\033[0;32mHealthy\033[0m'
OAS_CLUSTER_STATUS='\033[0;35mNot Active\033[0m'

# Update etc/issue
echo -e "\033[0;34m  ____                  ___   ____" > /etc/issue
echo " / __ \___  ___ ___    / _ | / __/" >> /etc/issue
echo "/ /_/ / _ \/ -_) _ \  / __ |_\ \  " >> /etc/issue
echo "\____/ .__/\__/_//_/ /_/ |_/___/  " >> /etc/issue
echo -e "    /_/                           \033[0m\n" >> /etc/issue
echo -e "\033[1;36m[ Open AS Communication Gateway $OAS_VERSION - www.openas.org ]\033[0m" >> /etc/issue 
echo -en "\033[1;36m[ Hostname: \033[0;37m$OAS_HOSTNAME \033[1;36m] \033[0m" >> /etc/issue
echo -e "\033[1;36m[ IP: \033[0;37m$OAS_IPADDR \033[1;36m]\033[0m\n" >> /etc/issue

# Update MOTD
echo -e "\033[0;34m  ____                  ___   ____" > /etc/motd
echo " / __ \___  ___ ___    / _ | / __/" >> /etc/motd
echo "/ /_/ / _ \/ -_) _ \  / __ |_\ \  " >> /etc/motd
echo "\____/ .__/\__/_//_/ /_/ |_/___/  " >> /etc/motd
echo -e "    /_/                           \033[0m" >> /etc/motd
echo -e "" >> /etc/motd
echo -e "\033[1;36m[ Open AS Communication Gateway $OAS_VERSION - www.openas.org ]\033[0m" >> /etc/motd 
echo -en "\033[1;36m[ Hostname: \033[0;37m$OAS_HOSTNAME \033[1;36m] \033[0m" >> /etc/motd
echo -e "\033[1;36m[ IP: \033[0;37m$OAS_IPADDR \033[1;36m]\033[0m" >> /etc/motd
echo -en "\033[1;36m[ Services Status: $OAS_SERVICE_STATUS \033[1;36m] \033[0m" >> /etc/motd
echo -e "\033[1;36m[ Cluster Status: $OAS_CLUSTER_STATUS \033[1;36m] \033[0m" >> /etc/motd
echo -e "\033[1;36m[ Type \033[0;33m'openas-cli help'\033[1;36m for a list of available commands. ]\033[0m" >> /etc/motd
echo -e "" >> /etc/motd

