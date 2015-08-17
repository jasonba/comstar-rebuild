#!/bin/bash

#
# Program       : comstar-rebuild.sh
# Author        : Jason.Banham@Nexenta.COM
# Date          : 2015-08-13 : 2015-08-17
# Version       : 0.05
# Usage         : comstar-rebuild.sh <path_to_collector_comstar_directory>
# Purpose       : Recreate the comstar configuration from a collector bundle
# Legal         : Copyright 2015, Nexenta Systems, Inc. 
#
# History       : 0.01 - Initial version
#		  0.02 - Added preflight checks
#		  0.03 - Added the target portal groups (tpg) script
#		  0.04 - Changed the interpreter from /bin/sh to /bin/bash for compatability purposes
#		  0.05 - Added check for LU's in a standby state as we can't process those
#

if [ "x$1" == "x" ]; then
    echo "Error: missing the path to the Collector comstar directory"
    exit 1
fi

shopt -s xpg_echo

PATH=$PATH:.
export PATH

COMSTAR_DIR="$1"

#
# Which version of collector has this been tested against?
#
COLLECTOR_VERIFIED=119

#
# The default names of the COMSTAR datafiles
#
STMFADM_LIST_LU="${COMSTAR_DIR}/stmfadm-list-lu-v.out"
ITADM_INITIATOR="${COMSTAR_DIR}/itadm-list-initiator-v.out"
TPGS="${COMSTAR_DIR}/itadm-list-tpg-v.out"
TARGETS="${COMSTAR_DIR}/itadm-list-target-v.out"
HOST_GROUPS="${COMSTAR_DIR}/stmfadm-list-hg-v.out"
TARGET_GROUPS="${COMSTAR_DIR}/stmfadm-list-tg-v.out"
VIEWS="${COMSTAR_DIR}/for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out"

CONFIG_FILES="$STMFADM_LIST_LU $ITADM_INITIATOR $TARGETS $HOST_GROUPS $TARGET_GROUPS $VIEWS"

#
# The names of the scripts that do the work
#
CREATE_LU="create-lu.pl"
CREATE_INIT="create-initiator.pl"
CREATE_TPGS="tpg.pl"
CREATE_TARGETS="target.pl"
CREATE_HG="hg.pl"
CREATE_TG="tg.pl"
CREATE_VIEWS="views.pl"

#
# Let's do some pre-validation checks
#
echo "Doing pre-validation \n"

if [ ! -d $COMSTAR_DIR ]; then
    echo "Could not find that directory, must exit"
    exit 1
fi

CFG_FAIL=0
for cfg_file in $CONFIG_FILES
do
    if [ ! -r $cfg_file ]; then
	echo "Could not find $cfg_file"
	CFG_FAIL=1
    fi
done
if [ $CFG_FAIL -eq 1 ]; then
    echo "Must exit due to missing COMSTAR configuration files" 
    exit 1
fi

#
# If an LU is in a standby state, the property values will be meaningless
# Check for this and abort if found
#

grep -q 'Access State.*: Standby' $STMFADM_LIST_LU
if [ $? -eq 0 ]; then
    echo "The logical units were found in a standby state, thus no property values could be found"
    echo "This could be from an ALUA based system, so check access from the other node"
    echo "If necessary, run the $CREATE_LU and other scripts manually."
    echo "Exiting"
    exit 1
fi

#
# These scripts have been tested with collector 1.1.9
#
COLLECTOR_CHECK=0
COLLECTOR_STATS="nf"	# Not Found

COLLECTOR_BASE="`dirname ${COMSTAR_DIR}`"
if [ -r ${COLLECTOR_BASE}/collector.stats ]; then
    COLLECTOR_STATS=${COLLECTOR_BASE}/collector.stats
fi
if [ -r ${COMSTAR_DIR}/collector.stats ]; then
    COLLECTOR_STATS=${COMSTAR_DIR}/collector.stats
fi
if [ $COLLECTOR_STATS != "nf" ]; then
    COLLECTOR_VER=`head -1 $COLLECTOR_STATS | awk '{print $2}'`
    COLLECTOR_VER_MUNGED=`echo $COLLECTOR_VER | sed -e 's/(//g' -e 's/)//g' -e 's/\.//g'`
    if [ $COLLECTOR_VER_MUNGED -ge $COLLECTOR_VERIFIED ]; then
	COLLECTOR_CHECK=1
    fi
fi

if [ $COLLECTOR_CHECK -eq 0 ]; then
    echo "INFO: Could not find collector version or your version $COLLECTOR_VER of collector has not been tested."
    echo "      If there are problems, please report back on collector, NexentaStor and comstar-rebuild versions"
    echo "      along with the output from the script, plus any errors generated."
fi

echo "... pre-validation finished.\n"
echo "Starting ...\n"

#
# Pre-flight checks performed, ready for take off
#
if [ -r ${STMFADM_LIST_LU} ]; then
    echo "### Creating lu's ..."
    $CREATE_LU $STMFADM_LIST_LU
fi
echo ""

if [ -r ${ITADM_INITIATOR} ]; then
    echo "### Creating initiators ..."
    $CREATE_INIT $ITADM_INITIATOR
fi
echo ""

if [ -r ${TPGS} ]; then
    echo "### Creating target portal groups ..."
    $CREATE_TPGS $TPGS
fi
echo ""

if [ -r $TARGETS ]; then
    echo "### Creating targets ..."
    $CREATE_TARGETS $TARGETS
fi
echo ""

if [ -r $HOST_GROUPS ]; then
    echo "### Creating host groups ..."
    $CREATE_HG $HOST_GROUPS
fi
echo ""

if [ -r $TARGET_GROUPS ]; then
    echo "### Creating target groups ..."
    $CREATE_TG $TARGET_GROUPS
fi

if [ -r $VIEWS ]; then
    echo "### Creating views ..."
    $CREATE_VIEWS $VIEWS
fi
