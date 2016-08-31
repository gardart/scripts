#!/bin/bash
# Restart nsca (Passive) service if many checks are failing
# Author: Gardar Thorsteinsson <gardart@gmail.com>

# Logging functions
#
readonly SCRIPT_NAME=$(basename $0)

log() {
  echo "$@"
  logger -p user.notice -t $SCRIPT_NAME "$@"
}

err() {
  echo "$@" >&2
  logger -p user.error -t $SCRIPT_NAME "$@"
}

# Script begins
#
num_passive_hosts_unreachable=`pynag livestatus --get hosts --columns "name state plugin_output" --filter "state = 1" | grep -i "No agent update received from client" | wc -l`;

if [ $num_passive_hosts_unreachable -gt 5 ]
then
        err "Number of Unreachable Passive checks:"$num_passive_hosts_unreachable":Restarting NSCA Service."
        /etc/init.d/nsca restart
else
        log "Number of Unreachable Passive Checks:"$num_passive_hosts_unreachable":No restart required."
fi
