#!/bin/bash

# Define constants
OLD_IFS=$IFS
TOOL=ovsdb-tool_set-controller.sh
DB=tcp:192.168.0.13:6640 #OVS eth2
INTERFACE=enp4s0
C1=tcp:192.168.56.17:6633
C2=tcp:192.168.56.16:6653
SAMPLES=(1 15)

# Initialize parameters
rangeSwitch=(1 1)
dirPathTool=.

# Funtion to print usage and options
function usage {
    printf "\nOptions:\n"
    printf "\t-r | --rangeSwitch\tNumeric (R)ange for switches in format INIT:FINAL. Default is '1:1'.\n"
    printf "\t-d | --dirPathTool\tPath to the (D)irectory that contains the tool. Default is '.'.\n"
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
        -d  | --dirPathTool )
            shift
            dirPathTool=$1;;
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

# Go to the directory that contains the tool
cd $dirPathTool
# Get the boundaries of the range of switches
startSwitch=${rangeSwitch[0]}
finalSwitch=${rangeSwitch[1]}
# Define the output filename
output="$finalSwitch.csv"
# Initialize the number of tests
test=0

# Run the tests, pausing 5 seconds between them
IFS=$OLD_IFS
for i in $(seq ${SAMPLES[0]} ${SAMPLES[1]})
do
    # Test to set the first controller
    test=$((test+1))
    echo "Test $test: sudo ./$TOOL -d $DB -i $INTERFACE -r $startSwitch:$finalSwitch -o $output -c $C1"
    sudo ./$TOOL -d $DB -i $INTERFACE -r "$startSwitch:$finalSwitch" -o $output -c $C1
    sleep 5
    # Test to set the second controller
    test=$((test+1))
    echo "Test $test: sudo ./$TOOL -d $DB -i $INTERFACE -r $startSwitch:$finalSwitch -o $output -c $C2"
    sudo ./$TOOL -d $DB -i $INTERFACE -r "$startSwitch:$finalSwitch" -o $output -c $C2
    sleep 5
done

