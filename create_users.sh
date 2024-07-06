#!/bin/bash


# Check if correct arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

# Input file containing usernames and groups such a file
INPUT_FILE="$1"

# Log file and password storage
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"


mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to generate a random password
generate_password() {
    tr -dc 'A-Za-z0-9@#$%^&*()_+' </dev/urandom | head -c 12
}

#####
while IFS=';' read -r username groups; do
    # Remove balnk spaces
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)

    # Skip empty lines....
    [ -z "$username" ] && continue

    # Create group
    if ! getent group "$username" > /dev/null; then
        groupadd "$username"
        echo "$(date): Group $username created" >> $LOG_FILE
    fi

    # Create users
    if ! id "$username" > /dev/null 2>&1; then
        password=$(generate_password)
        useradd -m -g "$username" -G "$(echo $groups | tr ',' ' ')" -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        echo "$username,$password" >> $PASSWORD_FILE
        echo "$(date): User $username created with groups $groups" >> $LOG_FILE
    else
        echo "$(date): User $username already exists" >> $LOG_FILE
        continue
    fi

    # Setting permissions
    chown -R "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    echo "$(date): Set permissions for /home/$username" >> $LOG_FILE
done < "$INPUT_FILE"

echo "User creation process completed."


