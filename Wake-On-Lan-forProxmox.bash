#!/bin/bash

# Attempts to start Proxmox VM or LXC that matches MAC address received on WOL message
# This could be dangerous if abused by spamming the interface with many packages
# so I would like to try no more than once per 5 seconds.
# In my case useful with Moonlight client
# Uses tcpdump on default proxmox interface, change the interface if needed.
#TODO change for monitoringloop.bash
while true; do
  sleep 5
  wake_mac=$(tcpdump -c 1 -UlnXi vmbr1 ether proto 0x0842 or udp port 9 2>/dev/null |\
  sed -nE 's/^.*20:  (ffff|.... ....) (..)(..) (..)(..) (..)(..).*$/\2:\3:\4:\5:\6:\7/p')
  echo "Captured magic packet for address: \"${wake_mac}\""
  echo -n "Looking for existing VM: "
  matches=($(grep -il ${wake_mac} /etc/pve/qemu-server/*))
  if [[ ${#matches[*]} -eq 0 ]]; then
    echo "${#matches[*]} found"
  echo -n "Looking for existing LXC: "
  matches=($(grep -il ${wake_mac} /etc/pve/lxc/*))
  if [[ ${#matches[*]} -eq 0 ]]; then
    echo "${#matches[*]} found"
    continue
  elif [[ ${#matches[*]} -gt 1 ]]; then
    echo "${#matches[*]} found, using first found"
  else
    echo "${#matches[*]} found"
  fi
  vm_file=$(basename ${matches[0]})
  vm_id=${vm_file%.*}
  details=$(pct status ${vm_id} -verbose | egrep "^name|^status")
  name=$(echo ${details} | awk '{print $2}')
  status=$(echo ${details} | awk '{print $4}')
  if [[ "${status}" != "stopped" ]]; then
    echo "SKIPPED CONTAINER ${vm_id} : ${name} is ${status}"
  else
    echo "STARTING CONTAINER ${vm_id} : ${name} is ${status}"
    pct start ${vm_id}
  fi
    continue
  elif [[ ${#matches[*]} -gt 1 ]]; then
    echo "${#matches[*]} found, using first found"
  else
    echo "${#matches[*]} found"
  fi
  vm_file=$(basename ${matches[0]})
  vm_id=${vm_file%.*}
  details=$(qm status ${vm_id} -verbose | egrep "^name|^status")
  name=$(echo ${details} | awk '{print $2}')
  status=$(echo ${details} | awk '{print $4}')
  if [[ "${status}" != "stopped" ]]; then
    echo "SKIPPED VM ${vm_id} : ${name} is ${status}"
  else
    echo "STARTING VM ${vm_id} : ${name} is ${status}"
    qm start ${vm_id}
  fi
done


#Source: https://forum.proxmox.com/threads/wake-on-lan-wol-for-vms-and-containers.143879/
