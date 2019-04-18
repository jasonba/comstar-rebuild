#!/bin/bash

#
# Program       : comstar-rebuild.sh
# Author        : Jason.Banham@Nexenta.COM
# Date          : 2015-08-13 : 2019-04-18
# Version       : 0.11
# Usage         : comstar-rebuild.sh <path_to_collector_comstar_directory>
# Purpose       : Recreate the comstar configuration from a collector or support bundle
# Legal         : Copyright 2015, 2019 Nexenta Systems, Inc. 
#
# History       : 0.01 - Initial version
#		  0.02 - Added preflight checks
#		  0.03 - Added the target portal groups (tpg) script
#		  0.04 - Changed the interpreter from /bin/sh to /bin/bash for compatability purposes
#		  0.05 - Added check for LU's in a standby state as we can't process those
#                 0.06 - Now supports NexentaStor 5.x support bundles in addition to 4.x collectors
#                 0.07 - Moved standby checking into the create-lu.pl script, so we don't need it here
#                 0.08 - Modified the script to handle Collectors and Support Bundles
#                 0.09 - Fixed the script to deal with CHAP secrets
#                 0.10 - Script now takes a -C switch to use stmfha which is cluster aware
#                 0.11 - Now accepts -i and -t switches if we know the CHAP secrets for initiator and target
#

#
# For stupid shells that switch off xpg echo functionality, switch it back on
#
shopt -s xpg_echo

PATH=$PATH:.
export PATH

#
# Setup some variables
#
LOG_TYPE="unknown"
VERSION="0.11"
CLUSTER=""
INITIATOR_SECRET="none"
TARGET_SECRET="none"

#
# Usage function
#
function usage
{
    echo "Usage: `basename $0` [-h] [-C] [-c <collector_location>/comstar ] [ -b <support_bundle_location>/comstar ] [ -i <initiator_chap_secret> ] [ -t <target_chap_secret> [-v]\n"
}

#
# Help function, display help when requested
#
function help
{
    usage
    echo "This script will take a collector or support bundle, review the comstar directory"
    echo "and then output a list of commands that can be used to manually rebuild a lost"
    echo "iSCSI/COMSTAR configuration"
}

#
# Does a simple verify of the collector to check version level, to see if we've tested against
# that release
#
function collector_verify
{
    #
    # These scripts have been tested with collector 1.1.9
    #
    COLLECTOR_CHECK=0
    COLLECTOR_STATS="nf"    # Not Found
    COLLECTOR_VER="(unknown)"
    
    #
    # In case we're given the path to a collector in the database, go up a directory to check for
    # the collector.stats file there
    #
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
}

#
# Does a simple verify of the support bundle to check version level, to see if we've tested against
# that release
#
function bundle_verify
{
    #
    # These scripts have been tested with a support bundle from a 5.1.x machine
    # which the bundle.json claims is version 1
    #
    BUNDLE_CHECK=0
    BUNDLE_JSON="nf"    # Not Found
    BUNDLE_VER="(unknown)"
    
    #
    # In case we're given the path to a collector in the database, go up a directory to check for
    # the collector.stats file there
    #
    BUNDLE_BASE="`dirname ${COMSTAR_DIR}`"
    if [ -r ${BUNDLE_BASE}/bundle.json ]; then
        BUNDLE_JSON=${BUNDLE_BASE}/bundle.json
    fi
    if [ $BUNDLE_JSON != "nf" ]; then
        BUNDLE_VER="`grep version $BUNDLE_JSON | sed -e 's/,//g' | awk '{print $2}'`"
        if [ $BUNDLE_VER -ge $BUNDLE_VERIFIED ]; then
            BUNDLE_CHECK=1
        fi
    fi

    if [ $BUNDLE_CHECK -eq 0 ]; then
        echo "INFO: Could not find support bundle version or your version $BUNDLE_VER of support bundle has not been tested."
        echo "      If there are problems, please report back on the support bundle, NexentaStor and comstar-rebuild versions"
        echo "      along with the output from the script, plus any errors generated."
    fi
}


#
# Process any arguments
#
OPTIND=1
while getopts b:c:i:t:Cvh argopt
do
    case "$argopt" in
        b) LOG_TYPE="bundle"
           COMSTAR_DIR="$OPTARG"

           #
           # Which version of support bundle has this been tested against?
           #
           BUNDLE_VERIFIED=1

           #
           # The default names of the COMSTAR datafiles in a 5.x support bundle
           #
           STMFADM_LIST_LU="${COMSTAR_DIR}/stmfadm_list-lu-v.out"
           ITADM_INITIATOR="${COMSTAR_DIR}/itadm_list-initiator-v.out"
           TPGS="${COMSTAR_DIR}/itadm_list-tpg-v.out"
           TARGETS="${COMSTAR_DIR}/itadm_list-target-v.out"
           HOST_GROUPS="${COMSTAR_DIR}/stmfadm_list-hg-v.out"
           TARGET_GROUPS="${COMSTAR_DIR}/stmfadm_list-tg-v.out"
           VIEWS="${COMSTAR_DIR}/for_lu_in_stmfadm_list-lu_cut-d-f3_do_echo_echo_lu_echo_stmfadm_list-view-l_lu_done.out"

           CONFIG_FILES="$STMFADM_LIST_LU $ITADM_INITIATOR $TARGETS $HOST_GROUPS $TARGET_GROUPS $VIEWS $TPGS"
           ;;

        c) LOG_TYPE="collector"
           COMSTAR_DIR="$OPTARG"

           #
           # Which version of collector has this been tested against?
           #
           COLLECTOR_VERIFIED=119

           #
           # The default names of the COMSTAR datafiles in a collector
           #
           STMFADM_LIST_LU="${COMSTAR_DIR}/stmfadm-list-lu-v.out"
           ITADM_INITIATOR="${COMSTAR_DIR}/itadm-list-initiator-v.out"
           TPGS="${COMSTAR_DIR}/itadm-list-tpg-v.out"
           TARGETS="${COMSTAR_DIR}/itadm-list-target-v.out"
           HOST_GROUPS="${COMSTAR_DIR}/stmfadm-list-hg-v.out"
           TARGET_GROUPS="${COMSTAR_DIR}/stmfadm-list-tg-v.out"
           VIEWS="${COMSTAR_DIR}/for-lu-in-stmfadm-list-lucut-d-f3-do-echo-echo-luecho-stmfadm-list-view-l-lu-done.out"

           CONFIG_FILES="$STMFADM_LIST_LU $ITADM_INITIATOR $TARGETS $HOST_GROUPS $TARGET_GROUPS $VIEWS $TPGS"
           ;;

        C) CLUSTER="-c"
           ;;

        h) help
           exit 0
           ;;

        i) INITIATOR_SECRET="$OPTARG"
           ;;

        t) TARGET_SECRET="$OPTARG"
           ;;

        v) echo "`basename $0`: version $VERSION"
           exit 0
           ;;

        ?) echo "Invalid option $OPTARG"
           ;;

        *) usage
           ;;
    esac
done

shift $((OPTIND-1))

if [ $OPTIND == 1 ]; then
    usage
    exit 0
fi

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
    echo "One or more logical units were found in a standby state, thus no property values could be found"
    echo "This could be from an ALUA based system, so check access from the other node"
    echo "If necessary, run the $CREATE_LU and other scripts manually."
fi

case $LOG_TYPE in
    bundle    ) echo "Detected a support bundle\n"
                bundle_verify
                ;;
    collector ) echo "Detected a collector\n"
                collector_verify
                ;;
    *         ) echo "Unknown log format detected, unable to perform any validation"
                ;;
esac
    
echo "... pre-validation finished.\n"
echo "Starting ...\n"

#
# Pre-flight checks performed, ready for take off
#
if [ -r ${STMFADM_LIST_LU} ]; then
    echo "### Creating lu's ..."
    $CREATE_LU $CLUSTER $STMFADM_LIST_LU
fi
echo ""

if [ -r ${ITADM_INITIATOR} ]; then
    echo "### Creating initiators ..."
    if [ "$INITIATOR_SECRET" == "none" ]; then
        $CREATE_INIT $CLUSTER $ITADM_INITIATOR
    else
        $CREATE_INIT $CLUSTER -s "$INITIATOR_SECRET" $ITADM_INITIATOR
    fi
fi
echo ""

if [ -r ${TPGS} ]; then
    echo "### Creating target portal groups ..."
    $CREATE_TPGS $CLUSTER $TPGS
fi
echo ""

if [ -r $TARGETS ]; then
    echo "### Creating targets ..."
    if [ "$TARGET_SECRET" == "none" ]; then
        $CREATE_TARGETS $CLUSTER $TARGETS
    else
        $CREATE_TARGETS $CLUSTER -s "$TARGET_SECRET" $TARGETS
    fi
fi
echo ""

if [ -r $HOST_GROUPS ]; then
    echo "### Creating host groups ..."
    $CREATE_HG $CLUSTER $HOST_GROUPS
fi
echo ""

if [ -r $TARGET_GROUPS ]; then
    echo "### Creating target groups ..."
    $CREATE_TG $CLUSTER $TARGET_GROUPS
fi

if [ -r $VIEWS ]; then
    echo "### Creating views ..."
    $CREATE_VIEWS $CLUSTER $VIEWS
fi
