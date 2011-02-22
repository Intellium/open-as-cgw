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


# asinfo.sh
# This file is given as login-shell for system user 'asinfo'
# For managing ssh/serial console based mechanism to get info about AS appliance

# Ignore signals
trap "" SIGINT SIGTERM SIGTSTP SIGQUIT

CFG_PATH='/etc/limes'

SERIAL=`cat ${CFG_PATH}/sn 2>/dev/null`
REVISION=`cat ${CFG_PATH}/versions | grep -e '^revision.*' | cut -d'=' -f2 2>/dev/null`
VERSION_MAIN=`cat ${CFG_PATH}/versions | grep -e '^main.*' | cut -d'=' -f2 2>/dev/null`
VERSION_SEC=`cat ${CFG_PATH}/avail_secversion 2>/dev/null`

HOSTNAME=`hostname --fqdn 2>/dev/null`
LOADAVG=`cat /proc/loadavg | awk '{print $1, $2, $3}' 2>/dev/null`
LAST_UPDATE=`cat ${CFG_PATH}/update_timestamp | sed 's/_/ /' | sed 's/-/:/g' 2>/dev/null`

MEM_TOTAL=`cat /proc/meminfo | grep MemTotal | awk '{print $2 $3}' 2>/dev/null`
MEM_FREE=`cat /proc/meminfo | grep MemFree | awk '{print $2 $3}' 2>/dev/null`
MEM_STAT="${MEM_FREE} / ${MEM_TOTAL}"

UPTIME_S=`cat /proc/uptime | awk '{ print $1 }' | cut -d'.' -f1`
UPTIME_M=`expr $UPTIME_S \/ 60 \% 60`
UPTIME_H=`expr $UPTIME_S \/ 60 \/ 60 \% 24`
UPTIME_D=`expr $UPTIME_S \/ 60 \/ 60 \/ 24`


echo "-------------------------------------------------------"
echo "      AS Communication Gateway System Information      "
echo "-------------------------------------------------------"
echo ""
echo "  Serial Number:                    ${SERIAL}"
echo "  System Version:                   ${VERSION_MAIN}"
echo "  Available Security Version:       ${VERSION_SEC}"
echo "  Revision:                         ${REVISION}"
echo "  Last update:                      ${LAST_UPDATE}"
echo "";
echo "  System Uptime:                    ${UPTIME_D}d ${UPTIME_H}h ${UPTIME_M}m ";
echo "  Fully qualified domain name:      ${HOSTNAME}"
echo "  Load average:                     ${LOADAVG}"
echo "  Available main memory:            ${MEM_STAT}"
