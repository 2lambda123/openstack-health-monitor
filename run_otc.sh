#!/bin/bash

# Specify image names, JumpHost ideally has sfw2-snat
# Options for the images: my openSUSE 15.2 (linux), Ubuntu 20.04 (ubuntu),
#  openSUSE Leap 15.2 (opensuse), CentOS 8 (centos)
# You can freely mix ...
#export JHIMG="Ubuntu 20.04"
#export JHIMG="openSUSE 15.2"
export JHIMG="Standard_Ubuntu_20.04_latest"
#export ADDJHVOLSIZE=2
export IMG="Standard_Ubuntu_20.04_latest"
#export IMG="openSUSE 15.2"
#export IMG="CentOS 8"
# DEFLTUSER from image_original_user property
#export DEFLTUSER=opensuse
export DEFLTUSER=ubuntu
export JHDEFLTUSER=ubuntu
# You can use a filter when listing images (because your catalog is huge)
#export JHIMGFILT="--property-filter os_version=openSUSE-15.0"
#export IMGFILT="--property-filter os_version=openSUSE-15.0"
# ECP flavors
#if test $OS_REGION_NAME == Kna1; then
export JHFLAVOR=s2.medium.1
export FLAVOR=s2.medium.1
#else
#export JHFLAVOR=1C-1GB-10GB
#export FLAVOR=1C-1GB-10GB
#fi
# EMail notifications sender address
export FROM=kurt@garloff.de
# Only use one AZ
#export AZS="eu-de-01 eu-de-02 eu-de-03"
export AZS="eu-de-01 eu-de-03"
export VAZS="eu-de-01 eu-de-03"
# Upload (compressed) logfiles and stats to container
export SWIFTCONTAINER=OS-HM-Logfiles
# NAMESERVER
export NAMESERVER=100.125.4.25

export OLD_OCTAVIA=1

# Assume OS_ parameters have already been sourced from some .openrc file
# export OS_CLOUD=gx-scs-healthmgr

export EMAIL_PARAM=${EMAIL_PARAM:-"scs@garloff.de"}

# Notifications & Alarms (pass as list, arrays can't be exported)
ALARM_EMAIL_ADDRESSES="scs@garloff.de"
NOTE_EMAIL_ADDRESSES="scs@garloff.de"
#ALARM_EMAIL_ADDRESSES="scs@garloff.de scs-monitoring@plusserver.com"
#NOTE_EMAIL_ADDRESSES="scs@garloff.de"
export ALARM_EMAIL_ADDRESSES NOTE_EMAIL_ADDRESSES

# Terminate early on auth error
openstack server list >/dev/null

# Find Floating IPs
FIPLIST=""
FIPS=$(openstack floating ip list -f value -c ID)
for fip in $FIPS; do
	FIP=$(openstack floating ip show $fip | grep -o "APIMonitor_[0-9]*")
	if test -n "$FIP"; then FIPLIST="${FIPLIST}${FIP}_
"; fi
done
# Cleanup previous interrupted runs
SERVERS=$(openstack server  list | grep -o "APIMonitor_[0-9]*_" | sort -u)
VOLUMES=$(openstack volume  list | grep -o "APIMonitor_[0-9]*_" | sort -u)
NETWORK=$(openstack network list | grep -o "APIMonitor_[0-9]*_" | sort -u)
LOADBAL=$(openstack loadbalancer list | grep -o "APIMonitor_[0-9]*_" | sort -u)
ROUTERS=$(openstack router  list | grep -o "APIMonitor_[0-9]*_" | sort -u)
SECGRPS=$(openstack security group list | grep -o "APIMonitor_[0-9]*_" | sort -u)
TOCLEAN=$(echo "$FIPLIST
$SERVERS
$VOLUMES
$NETWORK
$LOADBAL
$ROUTERS
$SECGRPS
" | grep -v '^$' | sort -u)
for ENV in $TOCLEAN; do
  echo "******************************"
  echo "CLEAN $ENV"
  bash ./api_monitor.sh -o -q -c CLEANUP $ENV
  echo "******************************"
done

#bash ./api_monitor.sh -c -x -d -n 8 -l last.log -e $EMAIL_PARAM -S -i 9
#exec api_monitor.sh -o -C -D -N 2 -n 8 -s -e sender@domain.org "$@"
exec ./api_monitor.sh -O -C -D -n 6 -s -b -B -a 2 -R "$@"
