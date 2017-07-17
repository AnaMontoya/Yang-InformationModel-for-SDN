#!/bin/bash

# Define constants
OLD_IFS=$IFS
TOOL=manager_set-controller.sh
SAMPLES=(1 15)

# Initialize parameters
rangesSwitch1=1:1
rangesSwitch2=1001:1001
dirPathTool=.

# Function to print usage and options
function usage {
    printf "\nOptions:\n"
    printf "\t-r1 | --rangesSwitch\t(R)anges of the number of switches in format INIT:FINAL for OVSDB. Default is '1:1'.\n"
    printf "\t-r2 | --rangesSwitch\t(R)anges of the number of switches in format INIT:FINAL for OF-CONFIG. Default is '1001:1001'.\n"
    printf "\t-d | --dirPathTool\tPath to the (D)irectory that contains the tool. Default is '.'.\n"
    printf "\t-h | --help\t\t(H)elp.\n\n"
}

# Obtain arguments
while [ "$1" != "" ]
do
    case $1 in
        -r1  | --rangesSwitch1 )
            shift
            IFS=':'
            rangesSwitch1=( $1 );;
	    -r2  | --rangesSwitch2 )
            shift
            IFS=':'
            rangesSwitch2=( $1 );;
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

# Get the boundaries of the range of switches OVSDB
startSwitch1=${rangesSwitch1[0]} 
finalSwitch1=${rangesSwitch1[1]}  

# Get the boundaries of the range of switches OF-CONFIG
startSwitch2=${rangesSwitch2[0]} 
finalSwitch2=${rangesSwitch2[1]}

output="$finalSwitch1.csv"
# Initialize the number of tests
test=0

# Run the tests, pausing 5 seconds between them
IFS=$OLD_IFS

for i in $(seq ${SAMPLES[0]} ${SAMPLES[1]})
do
    # Test to set the opendaylight controller
    test=$((test+1))
    echo "Test $test: ./$TOOL -r1 "$startSwitch1:$finalSwitch1" -r2 "$startSwitch2:$finalSwitch2" -set ODL -o $output"
	    ./$TOOL -r1 "$startSwitch1:$finalSwitch1" -r2 "$startSwitch2:$finalSwitch2" -set ODL -o $output
    sleep 5
    # Test to set the RYU controller
    test=$((test+1))
    echo "Test $test: ./$TOOL -r1 "$startSwitch1:$finalSwitch1" -r2 "$startSwitch2:$finalSwitch2" -set RYU -o $output"
	    ./$TOOL -r1 "$startSwitch1:$finalSwitch1" -r2 "$startSwitch2:$finalSwitch2" -set RYU -o $output
    sleep 5
done

