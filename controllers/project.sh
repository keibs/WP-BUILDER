#!/bin/bash

source ./keibs_projects/wp-builder/libraries/progress-bar.sh
source ./keibs_projects/wp-builder/helpers/logger.sh $2 $4
source ./keibs_projects/wp-builder/helpers/validation.sh

function run()
{
    echo "Preparing project..."

    INFO "Declaring project variables..."
    set -x
    FUNCTION_NAME=$1
    USER_ACCOUNT=$2
    USER_PASSWORD=$3
    USER_WEBSITE=$4
    set +x
    DEBUG "Project variables set."

    case $FUNCTION_NAME in
    "create") 
        INFO "Uploading project details..."
        create $USER_ACCOUNT $USER_PASSWORD $USER_WEBSITE;;
    *)
        EXCEPTION "Sorry, $FUNCTION_NAME does not exist in '$0' on line: $LINENO." 
        exit 1;;
    esac
}

function create()
{
    INFO "Checking project arguments..."
    check_arguments $@

    echo "Creating project..."

    INFO "Assigning project variables..." 
    set -x
    USER_ACCOUNT=$1
    USER_PASSWORD=$2
    USER_WEBSITE=$3
    set +x
    DEBUG "Username: $USER_ACCOUNT, Password: $USER_PASSWORD, Website: $USER_WEBSITE."

    echo "Creating version control repository..."

    INFO "Connecting to Bitbucket repository..."
    ./keibs_projects/wp-builder/classes/repository.sh create $USER_ACCOUNT $USER_WEBSITE
    check_errors

    echo "Creating environment..."

    INFO "Connecting to Elastic Beanstalk..."
    ./keibs_projects/wp-builder/classes/environment.sh create $USER_ACCOUNT $USER_PASSWORD $USER_WEBSITE
    check_errors

    set -x
    cd ~/clients_websites/$USER_ACCOUNT/$USER_WEBSITE
    set +x

    INFO "Connecting to Amazon Web Services..."

    echo "Creating database..."

    INFO "Creating environment database..."
    aws rds create-db-instance --db-instance-class db.t2.micro --db-instance-identifier $USER_ACCOUNT-$USER_WEBSITE-instance --db-name $USER_WEBSITE --master-username $USER_ACCOUNT --master-user-password $USER_PASSWORD --engine mysql --availability-zone us-east-1a --engine-version 5.7 --publicly-accessible --allocated-storage 5 --vpc-security-group-ids sg-02e74c4b --backup-retention-period 0 
    check_errors
    echo "Configuring database..."
    progress_bar 360
    DEBUG "Database created successfully."

    INFO "Retrieving environment information..."
    aws elasticbeanstalk describe-environments --environment-name $USER_ACCOUNT-$USER_WEBSITE > ../resources/$USER_WEBSITE-environment.json
    check_errors
    echo "Storing environment variables..."
    progress_bar 3
    DEBUG "Environment information retrieved successfully."

    INFO "Retrieving database information..."
    aws rds describe-db-instances --db-instance-identifier $USER_ACCOUNT-$USER_WEBSITE-instance > ../resources/$USER_WEBSITE-database.json
    check_errors
    echo "Storing database variables..."
    progress_bar 3
    DEBUG "Database information retrieved successfully."

    echo "Configuring DNS settings..."

    INFO "Assigning URL endpoint variable..." 
    LB=$(jq .Environments[].EndpointURL ../resources/$USER_WEBSITE-environment.json)
    check_errors
    DEBUG "EndpointURL: $LB."

    INFO "Assigning database endpoint variable..." 
    RDS_HOST=$(jq .DBInstances[].Endpoint.Address ../resources/$USER_WEBSITE-database.json)
    check_errors
    DEBUG "Database Endpoint: $RDS_HOST."

    INFO "Configuring DNS record set..." 
    set -x
    cp ~/keibs_projects/wp-builder/resources/create-record-set.json ../resources/create-$USER_WEBSITE-record-set.json
    sed -i "s/endpointDNSName/$LB/g" ../resources/create-$USER_WEBSITE-record-set.json
    sed -i "s/yourBusinessName/$USER_WEBSITE/g" ../resources/create-$USER_WEBSITE-record-set.json
    set +x
    DEBUG "Record set configured successfully."

    INFO "Creating DNS record set..." 
    aws route53 change-resource-record-sets --hosted-zone-id ZX3S4NYW0OPJ9 --change-batch file:///home/ubuntu/clients_websites/$USER_ACCOUNT/resources/create-$USER_WEBSITE-record-set.json
    check_errors
    DEBUG "Record set created successfully."

    echo "Updating environment variables..."

    INFO "Setting environment variables..." 
    eb setenv RDS_HOST=$RDS_HOST SITE_URL="https://$USER_WEBSITE.business.keibs.com"
    check_errors
    DEBUG "Environment variables set successfully." 

    echo "Finishing up project creation..."
    progress_bar 120  
    DEBUG "Project created successfully."

    echo "Your website URL is: https://$USER_WEBSITE.business.keibs.com"

    INFO "Clearing project variables..." 
    set -x
    USER_ACCOUNT=
    USER_PASSWORD=
    USER_WEBSITE=
    LB=
    RDS_HOST=
    set +x
    DEBUG "Project variables cleared successfully."

    echo "Project created successfully."
}

run $@