#!/bin/bash
#
# hd_check.sh: A script to monitor the health of a hard drive via its
# reallocated sector count, and generate a warning when the count
# changes. This is useful for keeping an eye on disk corruption caused
# by frequent poky/OE builds.
#
# $CACHEFILE is a place for keeping track of the last measured
# reallocated sector count. You'll want to change it.
#
# By default this script only generates output when issuing a
# warning. Run it via cron to get an email notification. Alternately,
# if you uncomment $WARNFILE below, the script will genereate a local
# file instead.
#
# A QnD script by Scott Garman <sgarman@zenlinux.com>

function usage() {
	echo "Usage: $0 <drive>"
	echo "Where <drive> is the drive to check (e.g, /dev/sda)"
}

if [ $# != 1 ]; then
	usage
	exit 1
fi

SMARTCTL=/usr/sbin/smartctl
TIMESTAMP=`date +%F_%k.%M.%S`
DRIVE=$1
HD=`echo "$DRIVE" | sed 's/^\/dev\///'`
CACHEFILE=/root/cache/hd_check_$HD

# Uncomment this and set WARNFILE if you'd like to generate a file
# instead of sending an email. I do this on local systems and usually
# set it to put a file on my desktop.
#WARNFILE="/home/username/Desktop/HD_DANGER_$TIMESTAMP.txt"

SANITY_CHECK=`echo "$HD" | sed 's/^[hs]d[a-z]$//'`
if [ "$SANITY_CHECK" != "" ]; then
	echo "Error: Unable to parse hard disk device $DRIVE"
	usage
	exit 1
fi
if [ ! -e "$DRIVE" ]; then
	echo "Error: Device $DRIVE does not exist!"
	usage
	exit 1
fi

COUNT=`$SMARTCTL -a $DRIVE | grep Reallocated_Sector_Ct | awk '{ print \$NF }'`
if [ "$COUNT" == "" ]; then
	echo "Error: Unable to parse Reallocated_Sector_Ct from '$SMARTCTL -a $DRIVE'"
	exit 1
fi

# If $CACHEFILE doesn't exist, assume this is the first time we're
# being run. Otherwise do the comparison and issue a warning if the
# count has changed.
if [ ! -e $CACHEFILE ]; then
	echo $COUNT > $CACHEFILE
else
	LAST_COUNT=`cat $CACHEFILE`
	if [ "$COUNT" != "$LAST_COUNT" ]; then
		if [ "$WARNFILE" == "" ]; then
			echo "DANGER: Reallocated sector count on $DRIVE changed from $LAST_COUNT to $COUNT!"
		else
			echo "DANGER: Reallocated sector count on $DRIVE changed from $LAST_COUNT to $COUNT!" > $WARNFILE
			chmod a+rw $WARNFILE
		fi

		echo $COUNT > $CACHEFILE
	fi
fi
