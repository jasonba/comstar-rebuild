#!/bin/sh

#
# Program       : comstar-rebuild.sh
# Author        : Jason.Banham@Nexenta.COM
# Date          : 2015-08-13
# Version       : 0.01
# Usage         : comstar-rebuild.sh <path_to_collector_comstar_directory>
# Purpose       : Recreate the comstar configuration from a collector bundle
# Legal         : Copyright 2015, Nexenta Systems, Inc. 
#
# History       : 0.01 - Initial version
#

if [ "x$1" == "x" ]; then
    echo "Error: missing the path to the Collector comstar directory"
    exit 1
fi

PATH=$PATH:.
export PATH

COMSTAR_DIR="$1"

#
# The default names of the COMSTAR datafiles
#
STMFADM_LIST_LU="${COMSTAR_DIR}/stmfadm-list-lu-v.out"
ITADM_INITIATOR="${COMSTAR_DIR}/itadm-list-initiator-v.out"
TARGETS="${COMSTAR_DIR}/itadm-list-target-v.out"
HOST_GROUPS="${COMSTAR_DIR}/stmfadm-list-hg-v.out"
TARGET_GROUPS="${COMSTAR_DIR}/stmfadm-list-tg-v.out"
VIEWS="${COMSTAR_DIR}/for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out"

#
# The names of the scripts that do the work
#
CREATE_LU="create-lu.pl"
CREATE_INIT="create-initiator.pl"
CREATE_TARGETS="target.pl"
CREATE_HG="hg.pl"
CREATE_TG="tg.pl"
CREATE_VIEWS="views.pl"

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
