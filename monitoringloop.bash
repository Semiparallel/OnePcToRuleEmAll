#!/bin/bash

# Main monitoring loop
intervalSeconds=5
TYPE_CHECKER_SCRIPT="./TypeChecker"

while true; do
    #TODO add TypeChecker.bash -> monitoring vm, qt statuses
    $TYPE_CHECKER_SCRIPT #TODO intern statuses
    #TODO Exit if none qt or vm startet
    #TODO Enter if one started and check if not already in loop   
    #in a extra file functions start_id(vm/ct) starts bash script handlerRessource.bash
    # Check every 5 seconds (adjust as needed)
    #Wake-On-Lan-forProxmox.bash implement
    sleep $intervalSeconds
done