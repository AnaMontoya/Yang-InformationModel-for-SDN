#!/bin/bash

# Define constants
OLD_IFS=$IFS

# Initialize parameters
rangeSwitch=(1 1)
db=unix://var/run/openvswitch/db.sock
server=127.0.0.1
user=ubuntu
controller=tcp:127.0.0.1:6653
option=delete

# Name of files
currentConfig="running-config.xml"
newConfig="new-running-config.xml"

# Function to modify the XML configuration file
function addControllerXml {
    # Constants
    BEGIN_SWITCH_REGEX="^\s*<switch>\s*$"
    END_SWITCH_REGEX="^\s*<\/switch>\s*$"
    
    #BEGIN_CONTROLLER_REGEX="^\s*<controller>\s*$"
    #END_CONTROLLER_REGEX="^\s*<\/controller>\s*$"
    ID_REGEX="^\s*<id>.*<\/id>\s*$"
    LOST_CONN_REGEX="^\s*<lost-connection-behavior>.*<\/lost-connection-behavior>\s*$"
    
    # Flags
    inSwitch=false
    inSwId=false
    
    # Parameter
    storedSwId=""
    
    # Tokenize the controller
    IFS=':'
    controllerTokenized=( $3 )
    controllerIP=${controllerTokenized[1]}
    controllerPort=${controllerTokenized[2]}
    controllerProtocol=${controllerTokenized[0]}
    
    IFS=''
    while read line || [[ -n $line ]]
    do
        # Check if the line is within the requested Switch tag
        if [[ $inSwId == true && "$line" =~ $LOST_CONN_REGEX && $storedSwId != "ofc-bridge" ]]
        then
            line=$line"\n\t\t<controllers>"
            line=$line"\n\t\t\t<controller nc:operation=\"create\">"
            line=$line"\n\t\t\t\t<id>"$storedSwId"_controller</id>"
            line=$line"\n\t\t\t\t<ip-address>"$controllerIP"</ip-address>"
            line=$line"\n\t\t\t\t<port>"$controllerPort"</port>"
            line=$line"\n\t\t\t\t<protocol>"$controllerProtocol"</protocol>"
            line=$line"\n\t\t\t</controller>"
            line=$line"\n\t\t</controllers>"
        fi
        # Check if the line is within the Switch tag
        if [[ $inSwitch == true ]]
        then
            # Check if the line is the Switch ID
            if [[ $inSwitch == true && "$line" =~ $ID_REGEX ]]
            then
                inSwId=true
                storedSwId=$(sed "s|^\s*<id>\(.*\)</id>\s*$|\1|" <<< "$line")
            # Check if the line is the end of the Switch tag
            elif [[ $inSwitch == true && "$line" =~ $END_SWITCH_REGEX ]]
            then
                inSwitch=false
                inSwId=false
            fi
        else
            # Check if the line is the begin of the Switch tag
            if [[ "$line" =~ $BEGIN_SWITCH_REGEX ]]
            then
                inSwitch=true
            fi
        fi
        # Write the new configuration XML
        printf "$line\n" >> $2
    done < $1
}

# Funtion to print usage and options
function usage {
    printf "\nOptions:\n"
    printf "\t-r | --rangeSwitch\t(R)ange of number of switches in format INIT:FINAL. Default is '1:1'.\n"
    printf "\t-d | --db\t\t(D)atabase OVSDB to connect and delete the controller of each switch. Default is 'unix://var/run/openvswitch/db.sock'.\n"
    printf "\t-s | --server\t\t(S)erver OF-Config to connect and modify the controller of each switch. Default is '127.0.0.1'.\n"
    printf "\t-u | --user\t\t(U)ser of the server OF-Config to login and enable operations. Default is 'ubuntu'.\n"
    printf "\t-c | --controller\t(C)ontroller to set to each switch. Default is 'tcp:127.0.0.1:6653'.\n"
    printf "\t-o | --option\t\t(O)ption to init the controller of each switch. Values are 'delete' or 'create'. Default is 'delete'.\n"
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
        -s  | --server )
            shift
            server=$1;;
        -u  | --user )
            shift
            user=$1;;
        -c  | --controller )
            shift
            controller=$1;;
        -o  | --option )
            shift
            option=$1;;
        -h  | --help )
            usage
            exit 0;;
        * )
            usage
            printf "\nERROR: '$1' is not an option.\n\n"
            exit 1;;
        esac
    shift
done

# Return to the old IFS
IFS=$OLD_IFS

# Check the requested option
if [[ $option == "delete" ]]
then
    # Delete the controller for each switch in the range
    for i in $(seq ${rangeSwitch[0]} ${rangeSwitch[1]})
    do
        # Delete the controller of the switch
        sudo ovs-vsctl --db=$db del-controller s$i
    done
elif [[ $option == "create" ]]
then
    # Get the running configuration XML from the OF-Config server
    netopeer-cli <<CLI
connect --login $user $server
get-config running --out $currentConfig
CLI
    echo "exit"
    
    # Add controllers to the current configuration XML
    addControllerXml $currentConfig $newConfig $controller

    # Apply the modified configuration XML on the OF-Config server
    netopeer-cli <<CLI
connect --login $user $server
edit-config running --config $newConfig
CLI
    echo "exit"

    # Delete created XML files
    rm $currentConfig $newConfig
fi

