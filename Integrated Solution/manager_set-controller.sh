#!/bin/bash

# Define constants
OLD_IFS=$IFS
OUT_DIR="out-managerdb"
TOOLRYUovs=ovsdb-tool_set-controllerRYU.sh
TOOLRYUofconf=ofconfig-tool_set-controllerRYU.sh
TOOLODLovs=ovsdb-tool_set-controllerODL.sh
TOOLODLofconf=ofconfig-tool_set-controllerODL.sh
interface=enp0s8
# Name of files
output="out.csv"

# Initialize parameters
rangesSwitch=1:1,1001:1001
dirPathTools=.
set=RYU

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
    printf "\t-d | --dirPathTool\tPath to the (D)irectory that contains the tool. Default is '.'.\n"
    printf "\t-set | --set\t\t(SET) controller. Values are 'RYU' or 'ODL'. Default is 'RYU'.\n"
    printf "\t-h | --help\t\t(H)elp.\n\n"
}

# Obtain arguments
while [ "$1" != "" ]
do
    case $1 in
        -d  | --dirPathTool )
            shift
            dirPathTool=$1;;
	-set  | --set )
            shift
            set=$1;;
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

# Go to the directory that contains the tool
cd $dirPathTools

if [[ $set == "RYU" ]]
then
    # set RYU controller
    
    echo "Test $TOOLRYUovs: ./$TOOLRYUovs"
     ./$TOOLRYUovs
    echo "Test $TOOLRYUofconf: ./$TOOLRYUofconf"
     ./$TOOLRYUofconf

elif [[ $set == "ODL" ]]
then
	# set ODL controller
    
    echo "Test $TOOLODLovs: ./$TOOLODLovs"
     ./$TOOLODLovs
    echo "Test $TOOLODLofconf: ./$TOOLODLofconf"
     ./$TOOLODLofconf

fi

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

