#!/bin/bash

source ./keibs_projects/wp-builder/helpers/logger.sh
source ./keibs_projects/wp-builder/helpers/validation.sh

function run()
{
    INFO "Declaring git repository variables..."
    set -x
    FUNCTION_NAME=$1
    USER_ACCOUNT=$2
    USER_PASSWORD=$3
    USER_WEBSITE=$4
    set +x
    DEBUG "Git variables set."

    case $FUNCTION_NAME in
    "create") 
        INFO "Uploading git variables..."
        create $USER_ACCOUNT $USER_PASSWORD $USER_WEBSITE;;
    *)
        EXCEPTION "Sorry, $FUNCTION_NAME does not exist in '$0' on line: $LINENO." 
        exit 1;;
    esac
}

function create()
{ 
    INFO "Assigning git variables..." 
    set -x
    USER_ACCOUNT=$1
    USER_PASSWORD=$2
    USER_WEBSITE=$3
    set +x
    DEBUG "Username: $USER_ACCOUNT, Password: $USER_PASSWORD, Website: $USER_WEBSITE."

    INFO "Cloning git repository..." 
    set -x
    cd ~/clients_websites/$USER_ACCOUNT
    rm -R $USER_WEBSITE
    set +x
    git clone --single-branch -b master https://keibs:Admin%40K3i8s@github.com/keibs/WP-TEMPLATE.git $USER_WEBSITE
    check_errors

    INFO "Configuring environment variables..." 
    set -x
    cd $USER_WEBSITE 
    sed -i "s/SSLCertificateId: arn:aws:acm:us-east-1:541431149269:certificate\/155c8e65-406f-4767-a4cc-170e6ef437a5/SSLCertificateId: arn:aws:acm:us-east-1:541431149269:certificate\/0f3dcd32-0c27-4e61-8802-6fcb58ad4413/g" .ebextensions/02_configure_environment.config
    sed -i "/RDS_HOST: kbs-wp-template.ctrvx2qwmour.us-east-1.rds.amazonaws.com/d" .ebextensions/02_configure_environment.config
    sed -i "s/wp_template_db/$USER_WEBSITE/g" .ebextensions/02_configure_environment.config
    sed -i "s/ykeita/$USER_ACCOUNT/g" .ebextensions/02_configure_environment.config
    sed -i "s/Jacob1992!/$USER_PASSWORD/g" .ebextensions/02_configure_environment.config 
    sed -i "/SITE_URL: https:\/\/template.keibs.com/d" .ebextensions/02_configure_environment.config
    set +x
    DEBUG "Environment variables configured successfully." 
    INFO "Saving changes..." 
    git add -A && git commit -m 'Initial commit.'
    # TODO: Create a conditional for the above command (git commit).
    DEBUG "Changes committed successfully." 
}

run $@