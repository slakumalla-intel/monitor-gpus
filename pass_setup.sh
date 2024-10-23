#!/bin/bash

HOSTS_FILE="hosts.txt"
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

generate_ssh_key() {
    if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
        mkdir -p "$SSH_DIR"
        ssh-keygen -t rsa -b 2048 -f "$PRIVATE_KEY" -N ""
    fi
}

setup_passwordless_ssh() {
    local host=$1
    local username=$2
    ssh-copy-id -i "$PUBLIC_KEY" "$username@$host"
    if [ $? -eq 0 ]; then
        echo "$host: Password-less SSH setup completed"
    else
        echo "$host: Password-less SSH setup failed"
    fi
}

main() {
    local username=$1

    if [ -z "$username" ]; then
        echo "Help Usage: $0 <username>"
        exit 1
    fi

    if [ ! -f "$HOSTS_FILE" ]; then
        echo "Hosts file not found: $HOSTS_FILE"
        exit 1
    fi

    generate_ssh_key

    while IFS= read -r host; do
        if [ -n "$host" ]; then
            setup_passwordless_ssh "$host" "$username"
        fi
    done < "$HOSTS_FILE"
}

main "$1"
