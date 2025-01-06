#!/bin/bash

# Proxmox Shell command to check the VM status: "qm status <VM_ID>"
# Sample TXT file format
# 100,VM,0
# 110,VM,1
# 111,VM,1
# 121,VM,2
# 130,VM,3


#VMID TYPE PROFILE VRAM
# Variables (you can modify based on your actual setup)
#TODOS Add Container Support
#       ADD if in Profile a VM of same profile wann start ask if sure?
#       # Add Support for Stop and start ct/vm if is lower priority
         #Make a look function if looked not stop automatically
MAX_GPU_VRAM=11  # Example maximum GPU VRAM value in GB (can be modified)
LOOKING_GLASS_ID=100
PROFILE_FILE="proxmox_ids.txt"  # Your TXT file with VM profiles
PROFILE_CHANGER_SCRIPT="./profileChanger.sh"  # Path to the profile changer script
PROFILE_OVERRIDE_TOML="/etc/vgpu_unlock/profile_override.toml"


calculate_used_vram() {
    local total_vram=0

    # Check if proxmox_ids.txt exists
    if [[ ! -f "$PROFILE_FILE" ]]; then
        echo "Error: proxmox_ids.txt file not found at $PROFILE_FILE"
        exit 1
    fi

    # Read proxmox_ids.txt, sum up the VRAM used by each running VM
    while IFS=, read -r vm_id vm_type profile gb; do
        if is_vm_running "$vm_id"; then
            total_vram=$((total_vram + gb))
        fi
    done < "$PROFILE_FILE"
        if ((used_vram >= MAX_GPU_VRAM)); then
        echo "Error: Total VRAM usage ($used_vram GB) exceeds or equals the limit ($MAX_GPU_VRAM GB)."
        exit 1
    fi

    echo "$total_vram"
}



# Function to check if a VM is running
is_vm_running() {
    local vm_id=$1
    if qm status "$vm_id" | grep -q "status: running"; then
        return 0  # VM is running
    else
        return 1  # VM is not running
    fi
}


# Function to calculate remaining VRAM
calculate_remaining_vram() {
    local used_vram=$1

    # Ensure we don't exceed the MAX_GPU_VRAM
    local remaining_vram=$((MAX_GPU_VRAM - used_vram))
    if ((remaining_vram < 0)); then
        remaining_vram=0
    fi

    echo "$remaining_vram"
}
# Function to calculate average VRAM of running VMs
#Iterates through the PROFILE_FILE.
#Sums up the VRAM of all running VMs and calculates the average.
calculate_average_vram() {
    local total_vram=0
    local count=0

    while IFS=, read -r vm_id vm_type profile gb; do
        if is_vm_running "$vm_id"; then
            total_vram=$((total_vram + gb))
            ((count++))
        fi
    done < "$PROFILE_FILE"

    if ((count > 0)); then
        echo $((total_vram / count))
    else
        echo 0
    fi
}

# Function to dynamically create a profile
create_profile_for_vm() {
    local vm_id=$1
    local avg_vram=$(calculate_average_vram)

    # Ensure a minimum VRAM allocation
    if ((avg_vram == 0)); then
        avg_vram=1  # Default to 1GB if no running VMs
    fi

    # Check if VM_ID exists in the file
    if grep -q "^$vm_id," "$PROFILE_FILE"; then
        # Extract the current profile
        local current_profile
        current_profile=$(grep "^$vm_id," "$PROFILE_FILE" | cut -d, -f3)

        # Replace the existing line with updated VRAM but keep the profile
        sed -i "s/^$vm_id,.*/$vm_id,VM,$current_profile,$avg_vram/" "$PROFILE_FILE"
        echo "Updated profile for VM_ID $vm_id with $avg_vram GB VRAM, keeping profile as '$current_profile'."
    else
        # If VM_ID does not exist, execute ProfileChecker.sh
        echo "VM_ID $vm_id not found in $PROFILE_FILE. Running ProfileChecker.sh..."
        ./profileChecker.sh "$vm_id"

        # After running ProfileChecker.sh, re-check if the VM_ID was added
        if grep -q "^$vm_id," "$PROFILE_FILE"; then
            echo "profileChecker.sh successfully updated the profile for VM_ID $vm_id."
        else
            # If ProfileChecker.sh didn't update, add a new line with default profile
            echo "$vm_id,VM,default,$avg_vram" >> "$PROFILE_FILE"
            echo "Created new profile for VM_ID $vm_id"
        fi
    fi
}

# Main logic
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <VM_ID>"
    exit 1
fi

VM_ID=$1

# Check if VM_ID exists in the profile file
if ! grep -q "^$VM_ID," "$PROFILE_FILE"; then
    echo "No profile found for VM_ID $VM_ID. Creating or updating profile..."
    create_profile_for_vm "$VM_ID"
else
    echo "Profile found for VM_ID $VM_ID. Proceeding with the script."
fi

# Calculate VRAM usage
used_vram=$(calculate_used_vram)
echo "Used VRAM: $used_vram GB"

# Calculate remaining VRAM
remaining_vram=$(calculate_remaining_vram "$used_vram")
echo "Remaining VRAM: $remaining_vram GB"

# Execute profileChanger if there’s remaining VRAM
if ((remaining_vram > 0)); then
    echo "Executing: $PROFILE_CHANGER_SCRIPT $VM_ID ${remaining_vram}GB"
    $PROFILE_CHANGER_SCRIPT "$VM_ID" "${remaining_vram}GB"
else
    echo "No VRAM left for allocation!"
    exit 1
fi
