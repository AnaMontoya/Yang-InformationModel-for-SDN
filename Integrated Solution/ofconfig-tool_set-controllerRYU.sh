#!/bin/bash

# Define constants
OLD_IFS=$IFS
#OUT_DIR="out-ofconfig"

# Initialize parameters
rangeSwitch=(1 1)
server=127.0.0.1
port=830
user=ubuntu
controller=tcp:127.0.0.1:6653
#interface=enp0s8

# Name of files
filterConfig="filter-config.xml"
currentConfig="running-config.xml"
newConfig="new-running-config.xml"
#output="out.csv"

function buildFilterXml {
    printf "<capable-switch xmlns=\"urn"\:"onf":"config":"yang\">\n" >> $1
    printf "\t<logical-switches>\n" >> $1
    printf "\t\t<switch>\n" >> $1
    printf "\t\t\t<id>"$2"</id>\n" >> $1
    printf "\t\t</switch>\n" >> $1
    printf "\t</logical-switches>\n" >> $1
    printf "</capable-switch>\n" >> $1
}

# Function to modify the controller in the XML configuration file
function modifyControllerXml {
    # Constants
    BEGIN_CONTROLLER_REGEX="^\s*<controller>\s*$"
    END_CONTROLLER_REGEX="^\s*<\/controller>\s*$"
    CONTROLLER_IP_REGEX="^\s*<ip-address>[0-9.]*<\/ip-address>\s*$"
    CONTROLLER_PORT_REGEX="^\s*<port>[0-9]*<\/port>\s*$"
    CONTROLLER_PROTOCOL_REGEX="^\s*<protocol>[A-Za-z0-9]*<\/protocol>\s*$"
    
    # Flags
    inController=false
    
    # Regex
    swIdRegex="^\s*<id>$3<\/id>\s*$"
    
    # Tokenize the controller
    IFS=':'
    controllerTokenized=( $4 )
    controllerIP=${controllerTokenized[1]}
    controllerPort=${controllerTokenized[2]}
    controllerProtocol=${controllerTokenized[0]}
    
    IFS=''
    while read line || [[ -n $line ]]
    do
        # Check if the line is within the Controller tag
        if [[ $inController == true ]]
        then
            # Check if the line is the IP address tag
            if [[ "$line" =~ $CONTROLLER_IP_REGEX ]]
            then
                line=$(sed "s|\(<ip\-address>\)[0-9.]*\(</ip\-address>\)|\1${controllerIP}\2|" <<< "$line")
            # Check if the line is the Port tag
            elif [[ "$line" =~ $CONTROLLER_PORT_REGEX ]]
            then
                line=$(sed "s|\(<port>\)[0-9]*\(</port>\)|\1${controllerPort}\2|" <<< "$line")
            # Check if the line is the Protocol tag
            elif [[ "$line" =~ $CONTROLLER_PROTOCOL_REGEX ]]
            then
                line=$(sed "s|\(<protocol>\)[A-Za-z0-9]*\(</protocol>\)|\1${controllerProtocol}\2|" <<< "$line")
            # Check if the line is the end of the Controller tag
            elif [[ "$line" =~ $END_CONTROLLER_REGEX ]]
            then
                inController=false
            fi
        else
            # Check if the line is the beginning of the Controller tag
            if [[ "$line" =~ $BEGIN_CONTROLLER_REGEX ]]
            then
                inController=true
            fi
        fi
        # Write the new configuration XML
        printf "$line\n" >> $2
    done < $1
}

ofrangeSwitch1=`cat IM.json | grep ietf-IM:NOSConfParameters | cut -c 38-41`
ofrangeSwitch2=`cat IM.json | grep ietf-IM:NOSConfParameters | cut -c 43-46`
server=`cat IM.json | grep ietf-IM:netDevAgentService | cut -d '"' -f4`
controller=`cat IM.json | grep ietf-IM:Nos | cut -c 20-40` #RYU
user=`cat IM.json | grep ietf-IM:Authentication | cut -d '"' -f4`
port=`cat IM.json | grep ietf-IM:netDevAgentPort | cut -d '"' -f4`
interfaceM=`cat IM.json | grep NetDevInterface | cut -d '"' -f4` 
output=`cat IM.json | grep ietf-IM:Statistics_NetDevRsrc | cut -d '"' -f4`

echo $ofrangeSwitch1;
echo $ofrangeSwitch2;
echo $server;
echo $controllerRYU;
echo $user;
echo $port;
echo $interfaceM;
echo $output;

# Set the controller for each switch in the range
IFS=$OLD_IFS
for i in $(seq $ofrangeSwitch1 $ofrangeSwitch2)
do
    # Build the XML filter for the switch
    buildFilterXml $filterConfig "s$i"
    # Get the current configuration of the switch
    netopeer-cli <<CLI
connect --login $user --port $port $server
get-config running --out $currentConfig --filter=$filterConfig
CLI
    echo "exit"
    # Generate a new XML configuration: set the controller to the switch
    modifyControllerXml $currentConfig $newConfig "s$i" $controller
    # Apply changes in new XML configuration on the OF-Config server
    netopeer-cli <<CLI
connect --login $user --port $port $server
edit-config running --config $newConfig
disconnect
CLI
    echo "exit"
    # Delete created XML files
    rm $filterConfig $currentConfig $newConfig
done

# Get the final time in milliseconds
#finalTime=$(($(date +%s%N)/1000000))
# Get the final received and transmitted traffic in bytes
#finalRxBytes=$(printrxbytes)
#finalTxBytes=$(printtxbytes)

# Compute the delta time in milliseconds
#deltaTime=$((finalTime-initialTime))
# Compute the delta received and transmitted traffic in bytes
#deltaRxBytes=$((finalRxBytes-initialRxBytes))
#deltaTxBytes=$((finalTxBytes-initialTxBytes))

# Print the delta time and traffic
#printf "\n"
#printf " ----------------------------------------\n"
#printf "| Time\t\t$deltaTime\t\tms\t|\n"
#printf "| RxTraffic\t$deltaRxBytes\t\tbytes\t|\n"
#printf "| TxTraffic\t$deltaTxBytes\t\tbytes\t|\n"
#printf " ----------------------------------------\n"
#printf "\n"

# Check out directory
#if [[ ! -d $OUT_DIR ]]
#then
#    mkdir $OUT_DIR
#fi
# Append measurements to file
#printf "$deltaTime,$deltaRxBytes,$deltaTxBytes\n" >> $OUT_DIR/$output

