#!/bin/bash

# Define constants
OLD_IFS=$IFS
OUT_DIR="out-ovsdb"

# Initialize parameters
rangeSwitch=(1 1)
db=unix://var/run/openvswitch/db.sock
controller=tcp:127.0.0.1:6653
interface=enp0s8

# Name of files
output="out.csv"

# Function to get the current received traffic in bytes
function printrxbytes {
    /sbin/ifconfig $interface | grep "RX bytes" | cut -d: -f2 | awk '{ print $1 }'
}

# Function to get the current transmitted traffic in bytes
function printtxbytes {
    /sbin/ifconfig $interface | grep "TX bytes" | cut -d: -f3 | awk '{ print $1 }'
}

# Funtion to print usage and options
function usage {
    printf "\nOptions:\n"
    printf "\t-r | --rangeSwitch\tNumeric (R)ange for switches in format INIT:FINAL. Default is '1:1'.\n"
    printf "\t-d | --db\t\tOVSDB (D)atabase to connect and set the controller of each switch. Default is 'unix://var/run/openvswitch/db.sock'.\n"
    printf "\t-c | --controller\t(C)ontroller to set to each switch. Default is 'tcp:127.0.0.1:6653'.\n"
    printf "\t-i | --interface\t(I)nterface to measure network throughput. Default is 'eth0'.\n"
    printf "\t-o | --output\t\t(O)utput CSV file to append measurements. Default is 'out.csv'.\n"
    printf "\t-h | --help\t\t(H)elp.\n\n"
}

# Obtain arguments
while [ "$1" != "" ]
do
    case $1 in
        -r  | --rangeSwitch )
            shift
            IFS=':'
            rangeSwitch=( $1 );;
        -d  | --db )
            shift
            db=$1;;
        -c  | --controller )
            shift
            controller=$1;;
        -i  | --interface )
            shift
            interface=$1;;
        -o  | --output )
            shift
            output=$1;;
        -h  | --help )
            usage
            exit 0;;
        * )
            usage
            printf "\nERROR: '$1' is not supported as an option.\n\n"
            exit 1;;
        esac
    shift
done

# Get the initial received and transmitted traffic in bytes
initialRxBytes=$(printrxbytes)
initialTxBytes=$(printtxbytes)

# Get the initial time in milliseconds
initialTime=$(($(date +%s%N)/1000000))

# Run the command for each switch in the range
IFS=$OLD_IFS
for i in $(seq ${rangeSwitch[0]} ${rangeSwitch[1]})
do
    # Set the controller to the switch
    ovs-vsctl --db=$db set-controller s$i $controller
done

# Get the final time in milliseconds
finalTime=$(($(date +%s%N)/1000000))
# Get the final received and transmitted traffic in bytes
finalRxBytes=$(printrxbytes)
finalTxBytes=$(printtxbytes)

# Compute the delta time in milliseconds
deltaTime=$((finalTime-initialTime))
# Compute the delta received and transmitted traffic in bytes
deltaRxBytes=$((finalRxBytes-initialRxBytes))
deltaTxBytes=$((finalTxBytes-initialTxBytes))

# Print the delta time and traffic
printf "\n"
printf " ----------------------------------------\n"
printf "| Time\t\t$deltaTime\t\tms\t|\n"
printf "| RxTraffic\t$deltaRxBytes\t\tbytes\t|\n"
printf "| TxTraffic\t$deltaTxBytes\t\tbytes\t|\n"
printf " ----------------------------------------\n"
printf "\n"

# Check out directory
if [[ ! -d $OUT_DIR ]]
then
    mkdir $OUT_DIR
fi
# Append measurements to file
printf "$deltaTime,$deltaRxBytes,$deltaTxBytes\n" >> $OUT_DIR/$output

