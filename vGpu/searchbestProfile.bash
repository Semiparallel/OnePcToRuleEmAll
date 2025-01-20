#!/bin/bash

# Define the file paths
FILE="profile_override_template.toml"
FILE_OVERRIDE="/etc/vgpu_unlock/profile_override.toml"

# Function to get the best profile
get_best_profile() {
    local input_size=$1
    local vmid=$2
    local best_profile=""
    local best_value=0
    #round down if float
    input_size=$(echo "scale=0; $input_size/1" | bc -l)
    # Loop through all profiles
    while IFS= read -r line; do
        if [[ $line =~ ^\[profile\.([0-9]+)GB\]$ ]]; then
            profile_size=${BASH_REMATCH[1]}
            if (( $(echo "$profile_size <= $input_size" | bc -l) && $(echo "$profile_size > $best_value" | bc -l) )); then
                best_profile=$profile_size
                best_value=$profile_size
            fi
        fi
    done < <(grep -oP '^\[profile\.\d+GB\]' "$FILE")

    echo "$best_profile"
}

# Extract values for a given profile
extract_profile_values() {
    local best_profile=$1
    local vmid=$2
    if [[ $best_profile == "512MB" ]]; then
        framebuffer=$(grep -A2 '\[profile\.512MB\]' "$FILE" | grep framebuffer | head -1 | awk -F'=' '{print $2}' | xargs)
        framebuffer_reservation=$(grep -A2 '\[profile\.512MB\]' "$FILE" | grep framebuffer_reservation | awk -F'=' '{print $2}' | xargs)
    else
        framebuffer=$(grep -A2 "\[profile\.${best_profile}GB\]" "$FILE" | grep framebuffer | head -1 | awk -F'=' '{print $2}' | xargs)
        framebuffer_reservation=$(grep -A2 "\[profile\.${best_profile}GB\]" "$FILE" | grep framebuffer_reservation | awk -F'=' '{print $2}' | xargs)
    fi

    # Replace or insert the values in the override file
    if grep -q "\[vm\.${vmid}\]" "$FILE_OVERRIDE"; then
        # Update existing entry
        sed -i "/\[vm\.${vmid}\]/,/^$/ {s/^framebuffer = .*/framebuffer = ${framebuffer}/; s/^framebuffer_reservation = .*/framebuffer_reservation = ${framebuffer_reservation}/;}" "$FILE_OVERRIDE"
    else
        # Add new entry
        echo -e "\n[vm.${vmid}]\nframebuffer = ${framebuffer}\nframebuffer_reservation = ${framebuffer_reservation}" >> "$FILE_OVERRIDE"
    fi
}
# Main script logic
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <VM_ID> <NEW_PROFILE_IN_GB>"
    echo "Example: $0 100 4"
    exit 1
fi

INPUT_VMID=$1
INPUT_SIZE=$2

# Support for 512MB Profile
if [ "$(echo "$INPUT_SIZE < 1" | bc -l)" -eq 1 ] && [ "$(echo "$INPUT_SIZE != 0.6" | bc -l)" -eq 1 ]; then
    BEST_PROFILE="512MB"
else
    BEST_PROFILE=$(get_best_profile "$INPUT_SIZE" "$INPUT_VMID")
fi

# Extract framebuffer values and add or update them in the override file
extract_profile_values "$BEST_PROFILE" "$INPUT_VMID"
if [ "$BEST_PROFILE" = "512MB" ]; then
  echo 0.5
else
  echo $BEST_PROFILE
fi



