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

# Log file
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Initialize log file
sudo touch "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"

# Initialize password file
sudo touch "$PASSWORD_FILE"
sudo chmod 600 "$PASSWORD_FILE"

# Function to log actions
log_action() {
    action=$1
    echo "$(date) - $action" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Function to check and create a group
check_and_create_group() {
    local group_name="$1"
    if ! getent group "$group_name" &>/dev/null; then
        sudo groupadd "$group_name"
        if [ $? -eq 0 ]; then
            log_action "Created group $group_name"
        else
            log_action "Failed to create group $group_name"
        fi
    fi
}

# Process each line in the file
while IFS=';' read -r username groups; do
    # Removing whitespace from username and groups
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user exists
    if id "$username" &>/dev/null; then
        log_action "User $username already exists. Skipping..."
        continue
    fi

    # Create user with home directory
    sudo useradd -m "$username"
    if [ $? -eq 0 ]; then
        log_action "Created user $username"
    else
        log_action "Failed to create user $username"
        continue
    fi

    # Create user's personal group if it doesn't exist
    check_and_create_group "$username"

    # Add user to specified groups
    IFS=',' read -ra user_groups <<< "$groups"
    for group in "${user_groups[@]}"; do
        # Check and create group if it doesn't exist
        check_and_create_group "$group"

        # Add user to the group
        sudo usermod -aG "$group" "$username"
        if [ $? -eq 0 ]; then
            log_action "Added user $username to group $group"
        else
            log_action "Failed to add user $username to group $group"
        fi
    done

    # Generate random password
    password=$(openssl rand -base64 12)

    # Set password for the user
    echo "$username:$password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        log_action "Set password for user $username"
    else
        log_action "Failed to set password for user $username"
    fi

    # Store password securely
    echo "$username,$password" | sudo tee -a "$PASSWORD_FILE" > /dev/null
    if [ $? -eq 0 ]; then
        log_action "Stored password for user $username"
    else
        log_action "Failed to store password for user $username"
    fi

done < "$FILE"

# Set correct permission for the passwords file
sudo chmod 600 "$PASSWORD_FILE"
log_action "Set correct permission for $PASSWORD_FILE"
