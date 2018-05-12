#!/bin/bash

source ./keibs_projects/wp-builder/helpers/logger.sh
source ./keibs_projects/wp-builder/helpers/validation.sh

function run()
{
    INFO "Declaring environment variables..."
    set -x
    FUNCTION_NAME=$1
    USER_ACCOUNT=$2
    USER_PASSWORD=$3
    USER_WEBSITE=$4
    set +x
    DEBUG "Environment variables set."

    case $FUNCTION_NAME in
    "create") 
        INFO "Uploading environment details..."
        create $USER_ACCOUNT $USER_PASSWORD $USER_WEBSITE;;
    *)
        EXCEPTION "Sorry, $FUNCTION_NAME does not exist in '$0' on line: $LINENO." 
        exit 1;;
    esac
}

function create()
{   
    INFO "Assigning environement variables..."
    set -x
    USER_ACCOUNT=$1
    USER_PASSWORD=$2
    USER_WEBSITE=$3
    set +x
    DEBUG "Username: $USER_ACCOUNT, Password: $USER_PASSWORD, Website: $USER_WEBSITE."

    INFO "Validating user account..." 
    verify_account $USER_ACCOUNT
    check_errors

    INFO "Validating user website..." 
    verify_website $USER_ACCOUNT $USER_WEBSITE
    check_errors

    INFO "Connecting to Github repository..."
    ./keibs_projects/wp-builder/classes/wp-template.sh create $USER_ACCOUNT $USER_PASSWORD $USER_WEBSITE 
    check_errors
    
    set -x
    cd ~/clients_websites/$USER_ACCOUNT/$USER_WEBSITE
    set +x

    INFO "Initializing environment..."    
    eb init clients-websites -r us-east-1 -k clients-access-key032518 -p PHP 
    check_errors
    DEBUG "Environment initialized successfully." 

    INFO "Creating environment..." 
    eb create $USER_ACCOUNT-$USER_WEBSITE --timeout 30
    check_errors
    DEBUG "Environment created successfully." 
 
    INFO "Selecting environment..." 
    eb use $USER_ACCOUNT-$USER_WEBSITE
    check_errors
    DEBUG "Environment selected successfully." 
}

run $@