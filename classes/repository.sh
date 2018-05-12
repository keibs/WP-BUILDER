#!/bin/bash

source ./keibs_projects/wp-builder/helpers/logger.sh

function run()
{
    INFO "Declaring bitbucket variables..."
    set -x
    FUNCTION_NAME=$1
    USER_ACCOUNT=$2
    USER_WEBSITE=$3
    set +x
    DEBUG "Bitbucket variables set."

    case $FUNCTION_NAME in
    "create") 
        INFO "Uploading bitbucket variables..."
        create $USER_ACCOUNT $USER_WEBSITE;;
    *)
        EXCEPTION "Sorry, $FUNCTION_NAME does not exist in '$0' on line: $LINENO."
        exit 1;;
    esac
}

function create()
{
    INFO "Assigning bitbucket variables..." 
    set -x
    USER_ACCOUNT=$1
    USER_WEBSITE=$2
    set +x
    DEBUG "Username: $USER_ACCOUNT, Website: $USER_WEBSITE."

    INFO "Creating repository..."
    bb create -u keibs -p Admin@K3i8s --private $USER_ACCOUNT-$USER_WEBSITE
    
    if [ $? -eq 0 ]; then
        DEBUG "Bitbucket repository created successfully."
    else
        ERROR "[ FAILED ]" 
        exit 1
    fi 
}

run $@