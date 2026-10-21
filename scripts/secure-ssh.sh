#!/bin/sh
# Lock down SSH on the tablet. The image ships with password 147147 and
# accepts SSH passwords on every interface, WiFi included.
#   ./secure-ssh.sh passwd     change the password of "user" (asks on the
#                              terminal). It is also the Phosh unlock PIN,
#                              so use digits only.
#   ./secure-ssh.sh keys-only  refuse SSH passwords; only keys in
#                              ~user/.ssh/authorized_keys still work
#   ./secure-ssh.sh off        stop and disable the SSH server
#   ./secure-ssh.sh on         undo keys-only and off
. "$(dirname "$0")/env.sh"
set -e
case $1 in
passwd)
	ssh -t $SSH_OPTS "user@$TABLET" passwd ;;
keys-only)
	tssh 'test -s ~/.ssh/authorized_keys' || {
		echo "no authorized key on the tablet: ssh-copy-id user@$TABLET first" >&2; exit 1; }
	# sshd keeps the first value it reads, so sort before the pmOS policy file
	tsudo 'printf "PasswordAuthentication no\nKbdInteractiveAuthentication no\n" > /etc/ssh/sshd_config.d/10-keys-only.conf && systemctl reload sshd && sshd -T 2>/dev/null | grep -i ^passwordauthentication' ;;
off)
	tsudo 'systemctl disable --now sshd' ;;
on)
	tsudo 'rm -f /etc/ssh/sshd_config.d/10-keys-only.conf; systemctl enable --now sshd; systemctl reload sshd' ;;
*)
	sed -n '2,11s/^# \{0,1\}//p' "$0"; exit 1 ;;
esac
