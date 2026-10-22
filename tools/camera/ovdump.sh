#!/bin/sh
# Dump OV5640 registers (sensor must be streaming): ovdump.sh REG COUNT ...
while [ $# -ge 2 ]; do
	h=$(printf "0x%02x 0x%02x" $(( $1 >> 8 )) $(( $1 & 255 )))
	printf "0x%04x:" $1; i2ctransfer -f -y 3 w2@0x3c $h r$2; shift 2
done
