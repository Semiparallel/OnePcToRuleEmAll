#!/bin/bash

# Paths
PROXMOX_IDS_FILE="proxmox_ids.txt"
SEARCH_BEST_PROFILE_AND_APPLY_SCRIPT="./searchbestProfile.bash"

# Function to update the profile using the external script
update_profile() {
    local vm_id=$1
    local new_profile=$2

    # Call the external script to search and apply the best profile
    local result=$($SEARCH_BEST_PROFILE_AND_APPLY_SCRIPT "$vm_id" "$new_profile")
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to update the profile for VM ID $vm_id"
        exit 1
    fi

    echo "$result"
}

# Function to update the proxmox_ids.txt file
update_proxmox_ids() {
    local vm_id=$1
    local new_profile=${2:-0}  # Default to 0 if new_profile is not provided or undefined

    # Check if proxmox_ids.txt exists
    if [[ ! -f "$PROXMOX_IDS_FILE" ]]; then
        echo "Error: proxmox_ids.txt file not found at $PROXMOX_IDS_FILE"
        exit 1
    fi

    # Update the proxmox_ids.txt file with the new profile in GB
    awk -F, -v vm_id="$vm_id" -v new_profile="$new_profile" '{
        if ($1 == vm_id) {
            $4 = new_profile;  # Update the profile column
        }
        print $0
    }' OFS=, "$PROXMOX_IDS_FILE" > temp_file && mv temp_file "$PROXMOX_IDS_FILE"
}

# Main script logic
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <VM_ID> <NEW_PROFILE_IN_GB>"
    echo "Example: $0 100 4"
    exit 1
fi

# Arguments passed
VM_ID=$1
NEW_PROFILE=$2

# Update the profile in profile_override.toml file
VRAM=$(update_profile "$VM_ID" "$NEW_PROFILE")

if [[ -z "$VRAM" ]]; then
    echo "Error: Failed to determine VRAM for VM ID $VM_ID"
    exit 1
fi

# Update proxmox_ids.txt with the new profile and column
update_proxmox_ids "$VM_ID" "$VRAM"

echo "Successfully updated VM ID $VM_ID to profile $VRAM GB in proxmox_ids.txt."
