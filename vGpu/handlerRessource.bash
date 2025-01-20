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

#FIX Use Templates provided not numbers in profilechanger Example -> in 7GB vRAM not supportet use Lowest profile
    # and change in proxmox_ids.txt
    # 
#TODOS Add Container Support
#       ADD if in Profile a VM of same profile wann start ask if sure?
#       # Add Support for start ct/vm if is lower/higher priority and VRAM is full.
         #Make a look function if looked not stop automatically
         
         # RES_USAGE_TOTAL 
        
MAX_GPU_VRAM=11  # Example maximum GPU VRAM value in GB (can be modified)
LOOKING_GLASS_ID=100
PROFILE_FILE="proxmox_ids.txt"  # Your TXT file with VM profiles
PROFILE_CHANGER_SCRIPT="./profileChanger.bash"  # Path to the profile changer script
TYPE_CHECKER_SCRIPT="../TypeChecker.bash"
MAX_GPU_VRAM=$(echo "$MAX_GPU_VRAM - 0.1" | bc ) # RTX 2080TI has less than 11GB in MB fo>calculate_used_vram() {
# Calculate used VRAM
calculate_used_vram() {
    local total_vram=0
    #Update PROFILE_FILE before using its values just in case...
    $TYPE_CHECKER_SCRIPT

    #Check if PROFILE_FILE exist
    if [[ ! -f "$PROFILE_FILE" ]]; then
        echo "Error: $PROFILE_FILE not found."
        exit 1
    fi

    #What to calculate based on PROFILE_FILE
    while IFS=, read -r vm_id vm_type profile gb; do
        case "$profile" in
            1)
                 # VM profile is 1 or 2, process it
                if is_vm_running "$vm_id"; then #Failback 1. Used ressource
                    total_vram=$(echo "$total_vram + ${gb:-0}" | bc -l) # Default to 0 if gb is not provided or undefined
                fi
            ;;
            2|3) #TODO seperate 3 in the way that its prompted if you woud like to free up this space used from TEMP VM/CT
                total_vram=$(echo "$total_vram + ${gb:-0}" | bc -l) 
            ;;
            *)
                # Default case for any other profile (not 1, 2, or 3)
            ;;
        esac
    done < "$PROFILE_FILE"




    if [ "$(echo "$total_vram >= $MAX_GPU_VRAM" | bc -l)" -eq 1 ]; then
        echo 0
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

# Function to calculate average VRAM of running VMs
#Iterates through the PROFILE_FILE.
#Sums up the VRAM of all running VMs and calculates the average.
calculate_average_vram() {
    local total_vram=0
    local count=0

    while IFS=, read -r vm_id vm_type profile gb; do
        if is_vm_running "$vm_id"; then
            total_vram=$(echo "$total_vram + $gb" | bc -l)
            ((count++))
        fi
    done < "$PROFILE_FILE"

    if ((count > 0)); then
        echo $(echo "$total_vram / $count" | bc -l)
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
        # If VM_ID does not exist, execute TypeChecker.bash
        echo "VM_ID $vm_id not found in $PROFILE_FILE. Running TypeChecker.bash..."
        $TYPE_CHECKER_SCRIPT

        # After running TypeChecker.bash, re-check if the VM_ID was added
        if grep -q "^$vm_id," "$PROFILE_FILE"; then
            echo "TypeChecker.bash successfully updated the profile for VM_ID $vm_id."
        else
            # If TypeChecker.bash didn't update, add a new line with default profile
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
echo "Used VRAM: $used_vram"

# Calculate remaining VRAM
# Ensure we don't exceed the MAX_GPU_VRAM
remaining_vram=$(echo "$MAX_GPU_VRAM - $used_vram" | bc -l)
if [ "$(echo "$remaining_vram < 0" | bc -l)" -eq 1 ]; then
    remaining_vram=0
fi

echo "Remaining VRAM: $remaining_vram GB"

# Execute profileChanger if theres remaining VRAM
if [ "$(echo "$remaining_vram > 0" | bc -l)" -eq 1 ]; then
    echo "Executing: $PROFILE_CHANGER_SCRIPT $VM_ID ${remaining_vram}GB"
    $PROFILE_CHANGER_SCRIPT "$VM_ID" "$remaining_vram"
else
    echo "No VRAM left for allocation!"
    exit 1
fi
