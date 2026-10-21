# Common settings, sourced by the other scripts. Override any of them in the
# environment, e.g. TABLET=192.168.1.42 ./status.sh
#
# TABLET     tablet address: 172.16.42.1 over USB (pmOS USB network), or its
#            WiFi address (see find-tablet.sh)
# TABLET_PW  password of "user" on the tablet, for sudo
# RKDEV      rkdeveloptool binary (see build-rkdeveloptool.sh)
# SHARE      folder shared with the pmbootstrap container as /share
: "${TABLET:=172.16.42.1}"
: "${TABLET_PW:=147147}"
: "${RKDEV:=rkdeveloptool}"
: "${SHARE:=$HOME/pmos-share}"
: "${PMOS_CONTAINER:=pmos}"

# The tablet's host key changes with every reflash, so don't record it
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=8 -o ControlMaster=no -o ControlPath=none"

tssh() { ssh $SSH_OPTS "user@$TABLET" "$@"; }
tscp() { scp -q $SSH_OPTS "$@"; }
# Run a shell command as root on the tablet
tsudo() { tssh "echo '$TABLET_PW' | sudo -S -p '' sh -c '$*'"; }
