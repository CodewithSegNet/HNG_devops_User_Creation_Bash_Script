#!/bin/bash

# Ensure that script runs with one argument
if [ "$#" -ne 1 ]; then
    echo "Usage: bash $0 <name-of-text-file>"
    exit 1
fi

# Get file name from the arg
FILE=$1

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "File $FILE not found!"
    exit 1
fi

# Ensure /var/secure directory exists
sudo mkdir -p /var/secure

# Ensure correct permission for /var/secure directory is set
sudo chmod 700 /var/secure

# Process each line in the file
while IFS=';' read -r username groups; do
    # Removing whitespace from username and groups
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping..."
        continue
    fi

    # Create user with home directory
    sudo useradd -m "$username"

    # Create user's personal group
    sudo groupadd "$username"

    # Add user to specified groups
    IFS=',' read -ra user_groups <<< "$groups"
    for group in "${user_groups[@]}"; do
        sudo usermod -aG "$group" "$username"
    done

    # Generate random password
    password=$(openssl rand -base64 12)

    # Set password for the user
    echo "$username:$password" | sudo chpasswd

    # Log actions
    action="User creation: $username"
    echo "$(date) - $action" | sudo tee -a /var/log/user_management.log > /dev/null

    # Store password securely 
    echo "$username,$password" | sudo tee -a /var/secure/user_passwords.csv > /dev/null

done < "$FILE"
