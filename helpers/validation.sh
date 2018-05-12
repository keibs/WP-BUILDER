#!/bin/bash

function verify_account()
{
    INFO "Assigning user account variable..."
    set -x
    USER_ACCOUNT=$1
    set +x
    DEBUG "Username: $USER_ACCOUNT."

    if [ -d "clients_websites/$USER_ACCOUNT" ]; then
        DEBUG "$USER_ACCOUNT account found." 
    else
        INFO "Creating $USER_ACCOUNT account directory..." 
        set -x
        mkdir clients_websites/$USER_ACCOUNT 
        mkdir clients_websites/$USER_ACCOUNT/resources
        set +x
        DEBUG "$USER_ACCOUNT account directory created successfully." 
    fi 
}

function verify_website()
{
    INFO "Assigning user account and user website variables..."
    set -x
    USER_ACCOUNT=$1
    USER_WEBSITE=$2
    set +x
    DEBUG "Username: $USER_ACCOUNT, Website: $USER_WEBSITE."

    if [ -d "clients_websites/$USER_ACCOUNT/$USER_WEBSITE" ]; then
        EXCEPTION "$USER_WEBSITE website already exist in '$0' on line: $LINENO."
        exit 1
    else
        INFO "Creating $USER_WEBSITE website directories..." 
        set -x
        mkdir clients_websites/$USER_ACCOUNT/$USER_WEBSITE
        set +x
        DEBUG "$USER_WEBSITE website directories created successfully."
    fi 
}

function check_arguments()
{
    REQUIRED_ARGS=3
    num_args=$#

    if [ $num_args -ne $REQUIRED_ARGS ]; then
        EXCEPTION "Invalid number of arguments in '$0' on line: $LINENO. Use this script with: '$0 <account_name> <account_password> <website_name>'" 
        exit 1
    else
        DEBUG "Arguments validated successfully."
    fi
}

function check_errors()
{
    if [ $? -eq 0 ]; then
        DEBUG "[ OK ]"
    else
        ERROR "[ FAILED ]" 
        exit 1
    fi 
}
