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

# Check for entries with 'X' profile and prompt the user to assign a number
echo "Checking for entries with 'X' profile..."
UPDATED=false
while grep -q ",X$" "$OUTPUT_FILE"; do
  # Get the first entry with 'X' in the profile
  ENTRY=$(grep ",X$" "$OUTPUT_FILE" | head -n 1)
  ID=$(echo $ENTRY | cut -d',' -f1)
  TYPE=$(echo $ENTRY | cut -d',' -f2)

  # Prompt the user for a numeric profile
  echo "Entry: ID=$ID, Type=$TYPE, Status=$STATUS"
  while true; do
    read -p "Enter a numeric profile for this entry: " PROFILE
    if [[ $PROFILE =~ ^[0-9]+$ ]]; then
      break
    else
      echo "Invalid input. Please enter a numeric value."
    fi
  done

  # Update the profile in the file
  sed -i "s/^$ID,$TYPE,X$/$ID,$TYPE,$PROFILE/" "$OUTPUT_FILE"
  UPDATED=true
done

if $UPDATED; then
  echo "All 'X' profiles have been updated."
else
  echo "No 'X' profiles found."
fi
