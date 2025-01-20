#!/bin/bash
# Output file
OUTPUT_FILE="proxmox_ids.txt"

# Create the file if it doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
  echo "ID,Type,Status,CustomVar" > $OUTPUT_FILE
fi

# Collect VM information and add only new entries
echo "Collecting VM information..."
qm list --full | while read -r line; do
  ID=$(echo $line | awk '{print $1}')
  if [[ $ID =~ ^[0-9]+$ ]]; then
    # Check if the ID already exists in the file with a profile not equal to 'X'
    if ! grep -q "^$ID,VM," "$OUTPUT_FILE" || grep -q "^$ID,VM,.*,X" "$OUTPUT_FILE"; then
      # If not registered or has 'X' profile, add or update the entry
      grep -v "^$ID,VM," "$OUTPUT_FILE" > temp && mv temp "$OUTPUT_FILE" # Remove any existing entry
      echo "$ID,VM,X" >> $OUTPUT_FILE
    fi
  fi
done

# Collect CT information and add only new entries
echo "Collecting CT information..."
pct list --full | while read -r line; do
  ID=$(echo $line | awk '{print $1}')
  if [[ $ID =~ ^[0-9]+$ ]]; then
    # Check if the ID already exists in the file with a profile not equal to 'X'
    if ! grep -q "^$ID,CT," "$OUTPUT_FILE" || grep -q "^$ID,CT,.*,X" "$OUTPUT_FILE"; then
      # If not registered or has 'X' profile, add or update the entry
      grep -v "^$ID,CT," "$OUTPUT_FILE" > temp && mv temp "$OUTPUT_FILE" # Remove any existing entry
      echo "$ID,CT,X" >> $OUTPUT_FILE
    fi
  fi
done

echo "Information updated in $OUTPUT_FILE."

# Function to check VM status
vm_status() {
    local vm_id=$1
    if qm status "$vm_id" | grep -q "status: paused"; then
        return 3  # Paused
    elif qm status "$vm_id" | grep -q "status: stopped"; then
        return 0  # Stopped
    else
        return 1  # Running
    fi
}

# Function to check container status
ct_status() {
    local ct_id=$1
    if pct status "$ct_id" | grep -q "status: paused"; then
        return 3  # Paused
    elif pct status "$ct_id" | grep -q "status: stopped"; then
        return 0  # Stopped
    else
        return 1  # Running
    fi
}


"""
#TODO Placeholder functions for actions 
On_Change_Status from 0-4
1. Reserved Ressource (Genutze ressource)
2. Potentiell nutzbarer aber nicht in gebrauch. Das kein neustart
 der 1. notendig ist. 
Kann auch deaktiviert sein.
3. Gespeicherte Zustände von Pausierten VM/CT's
Die potentiell reaktiviert werden können.Müssen auf dem selben profile.
4. rest Ressource, activ, inactive
0. Stopped
"""

on_vm_running() {
    local vm_id=$1
    echo "VM $vm_id is running. (Placeholder function)"

}

on_vm_paused() {
    local vm_id=$1
    echo "VM $vm_id is paused. (Placeholder function)"
}

on_vm_stopped() {
    local vm_id=$1
    echo "VM $vm_id is stopped. (Placeholder function)"
}


# Read the file and process each line
while IFS=',' read -r vm_id type prio vram; do
    # Skip the header
    [[ "$vm_id" == "vmid" ]] && continue

    # Check the status of VM or Container and update Prio
    new_prio=0  # Default priority

    if [[ "$type" == "VM" ]]; then
        vm_status "$vm_id"
        new_prio=$?
    else
        ct_status "$vm_id"
        new_prio=$?
    fi

    # Perform actions based on status
    case $new_prio in
        1)
            on_vm_running "$vm_id"
        ;;
        3)
            on_vm_paused "$vm_id"
        ;;
        0)
            on_vm_stopped "$vm_id"
        ;;
    esac

    # Update the priority in the file (temporary output to a new file)
    echo "$vm_id,$type,$new_prio,$vram" >> updated_vms.txt

done < "$OUTPUT_FILE"

# Replace the original file with the updated one
mv updated_vms.txt "$OUTPUT_FILE"

echo "Priority updated based on status."
