#!/bin/bash

BLOCKLIST_FILE=/tmp/blocklist.de.txt
BLOCKLIST_URL='https://lists.blocklist.de/lists/all.txt'

command -v ipset > /dev/null 2>&1 || { echo >&2 "missing ipset.  Aborting."; exit 1; }
command -v iptables > /dev/null 2>&1 || { echo >&2 "missing ipt.  Aborting."; exit 1; }

iptables -nL INPUT | grep -q "blocklist.de src"
if [[ $? -ne 0 ]]; then
        echo "blocklist.de is not used in INPUT chain!"
        iptables -I INPUT -m set --match-set blocklist.de src -j DROP
fi

# create new set
ipset create -exist blocklist.de hash:ip timeout 86400

if [ -f "${BLOCKLIST_FILE}" ]; then
        rm "${BLOCKLIST_FILE}"
fi
if [ -f "${BLOCKLIST_FILE}.gz" ]; then
        rm "${BLOCKLIST_FILE}.gz"
fi

wget --header="accept-encoding: gzip" -q "${BLOCKLIST_URL}" -O ${BLOCKLIST_FILE}.gz && gunzip ${BLOCKLIST_FILE}.gz

if [[ $? -ne 0 ]]; then
        echo "Error getting new blocklist"
        exit 1
fi

for IP in $(grep -v ':' < "${BLOCKLIST_FILE}" |sort -V)
do
       ipset add -exist blocklist.de $IP
done
# echo -en "added IPs: "
# wc -l ${BLOCKLIST_FILE}
rm "${BLOCKLIST_FILE}"
