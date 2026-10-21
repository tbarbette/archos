#!/bin/sh
# Wait until SSH answers (after a reboot or a flash). Default timeout 5 min.
. "$(dirname "$0")/env.sh"
end=$(( $(date +%s) + ${1:-300} ))
while [ "$(date +%s)" -lt $end ]; do
	ssh $SSH_OPTS -o BatchMode=yes "user@$TABLET" true 2>/dev/null && { echo up; exit 0; }
	sleep 3
done
echo "timeout" >&2; exit 1
