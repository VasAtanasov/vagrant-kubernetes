#!/bin/bash
#
# Add host to /etc/hosts

set -euxo pipefail

# Path to your hosts file
HOSTS_FILE="/etc/hosts"

if grep -q "$IP" /etc/hosts; then
  echo "$IP, already exists: $(grep $IP $HOSTS_FILE)"
else
  echo "Adding $HOSTNAME to $HOSTS_FILE..."
  printf "%s\t%s\t%s\n" "$IP" "$HOSTNAME" "$HOST_ALIAS" | sudo tee -a "$HOSTS_FILE" >/dev/null

  if grep -q "$IP" /etc/hosts; then
    echo "$HOSTNAME was added succesfully:"
    echo "$(grep $HOSTNAME /etc/hosts)"
  else
    echo "Failed to add $HOSTNAME"
  fi
fi
