#!/bin/bash

KEY="${HOME}/.ssh/id_rsa.pub"
USER="ubuntu"  # Change this to your actual remote user if needed

if [ ! -f "$KEY" ]; then
  echo "❌ SSH public key not found at $KEY"
  exit 1
fi

while read -r line; do
  IP=$(echo "$line" | awk '{print $1}')
  HOST=$(echo "$line" | awk '{print $2}')
  NAME=$(echo "$line" | awk '{print $3}')
  
  echo "🔑 Copying SSH key to $NAME ($IP)..."
  ssh-copy-id -i "$KEY" "$USER@$IP"
done < machines.txt
