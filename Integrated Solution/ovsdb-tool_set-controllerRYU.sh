#!/bin/bash

# Define constants
OLD_IFS=$IFS
#OUT_DIR="out-ovsdb"

# Initialize parameters
rangeSwitch=(1 1)
db=unix://var/run/openvswitch/db.sock
controller=tcp:127.0.0.1:6653
#interface=enp0s8

# Functions to catch information form json files
#IFS=':';
ovrangeSwitch1=`cat IM.json | grep ietf-IM:NOSConfParameters | cut -c 34`
ovrangeSwitch2=`cat IM.json | grep ietf-IM:NOSConfParameters | cut -c 36`
db=`cat IM.json | grep ietf-IM:netDevs | cut -c 24-44`
controllerRYU=`cat IM.json | grep ietf-IM:Nos | cut -c 20-41` #RYU
controllerODL=`cat IM.json | grep ietf-IM:Nos | cut -c 43-65` #ODL
interfaceM=`cat IM.json | grep NetDevInterface | cut -d '"' -f4` 
output=`cat IM.json | grep ietf-IM:Statistics_NetDevRsrc | cut -d '"' -f4`

echo $ovrangeSwitch1;
echo $ovrangeSwitch2;
echo $db;
echo $controllerRYU;
echo $controllerODL;
echo $interfaceM;
echo $output;


# Run the command for each switch in the range
IFS=$OLD_IFS
for i in $(seq $ovrangeSwitch1 $ovrangeSwitch2)
do
    # Set the controller to the switch
    ovs-vsctl --db=$db set-controller s$i $controllerRYU
done