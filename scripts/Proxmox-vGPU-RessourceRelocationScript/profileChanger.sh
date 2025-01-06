#!/bin/bash

# Paths
PROFILE_OVERRIDE_FILE="profile_override_test.toml"
PROXMOX_IDS_FILE="proxmox_ids.txt"

update_profile() {
    local vm_id=$1
    local new_profile=$2

    # Check if the file exists
    if [[ ! -f "$PROFILE_OVERRIDE_FILE" ]]; then
        echo "Error: Profile override file not found at $PROFILE_OVERRIDE_FILE"
        exit 1
    fi
    
    # Replace the profile in the PROFILE_OVERRIDE_FILE
    sudo sed -i "/\[vm.${vm_id}\]/,/^$/ s/^profile = \".*\"/profile = \"${new_profile}\"/" "$PROFILE_OVERRIDE_FILE"
}

update_proxmox_ids() {
    local vm_id=$1
    local new_profile=$2

    # Check if proxmox_ids.txt exists
    if [[ ! -f "$PROXMOX_IDS_FILE" ]]; then
        echo "Error: proxmox_ids.txt file not found at $PROXMOX_IDS_FILE"
        exit 1
    fi

    # Update the proxmox_ids.txt with the new profile and additional column
    awk -F, -v vm_id="$vm_id" -v new_profile="$new_profile" '{
        if ($1 == vm_id) {
            $4 = new_profile+"GB";  # Replace the profile column with the new profile (GB)
        }
        print $0
    }' OFS=, "$PROXMOX_IDS_FILE" > temp_file && mv temp_file "$PROXMOX_IDS_FILE"
}

# Check input arguments
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <VM_ID> <NEW_PROFILE_IN_GB>"
    echo "Example: $0 100 4"
    exit 1
fi

# Arguments passed
VM_ID=$1
NEW_PROFILE=$2

# Update the profile in profile_override.toml file
update_profile "$VM_ID" "$NEW_PROFILE"

# Update proxmox_ids.txt with the new profile and column
update_proxmox_ids "$VM_ID" "$NEW_PROFILE"

