#!/bin/sh
# Log into the tablet, or run a command on it: ./ssh.sh uptime
. "$(dirname "$0")/env.sh"
exec ssh $SSH_OPTS "user@$TABLET" "$@"
