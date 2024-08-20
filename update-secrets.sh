#!/bin/bash

# Function to display the help text
display_help() {
    echo "Usage: $0 {mcci-internal|mcci-dev|mcac|mcam-internal|mcam-dev} [--no-delete] [--conf=\"SOME_CONF\"] [-h|--help]"
    echo
    echo "This script updates secrets for the specified project."
    echo
    echo "Arguments:"
    echo "  mcci-internal, mcci-dev, mcac, mcam-internal, mcam-dev"
    echo "                         The project for which the secrets should be updated."
    echo "  --no-delete            Do not delete the existing secret before creating the new one."
    echo "  --conf=\"SOME_CONF\"     Provide additional configuration parameter."
    echo "  --json-dir=\"SOME_DIR\"  Provides the directory where the json files with secrets are located"
    echo "  -h, --help             Display this help text."
    echo
    exit 0
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
fi

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
    display_help
    exit 1
fi

# Define variables
CONF_PARAM=""
NO_DELETE="false"
JSON_DIR="${HOME}/H2O/Secrets"

# Parse the arguments
for arg in "$@"; do
    case $arg in
        --json-dir=*)
            JSON_DIR="${arg#*=}"
            shift
            ;;
        --conf=*)
            CONF_PARAM="--conf=${arg#*=}"
            shift
            ;;
        -h|--help)
            display_help
            ;;
        --no-delete)
            NO_DELETE="true"
            shift
            ;;
        *)
            PROJECT=$arg
            ;;
    esac
done

# Validate project
case $PROJECT in
    mcam-internal|mcam-dev)
        SECRET_NAME="mc-access-manager-secrets"
        ;;
    mcci-internal|mcci-dev)
        SECRET_NAME="mc-customer-insights-secrets"
        ;;
    mcac)
        SECRET_NAME="wave-mc-admin-center-secrets"
        ;;
    *)
        echo "Invalid project. Must be one of: mcci-internal, mcci-dev, mcac, mcam-internal, mcam-dev"
        exit 1
        ;;
esac

# Define the JSON file based on the project
JSON_FILE="${JSON_DIR}/${PROJECT}-secrets.json"

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file $JSON_FILE does not exist."
    exit 1
fi

# Parse the JSON file and get the key-value pairs
KEY_VALUES=($(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$JSON_FILE"))

# Check if there are any key-value pairs in the JSON file
if [ ${#KEY_VALUES[@]} -eq 0 ]; then
    echo "Error: No key-value pairs found in $JSON_FILE."
    exit 1
fi

# Delete the existing secret if --no-delete flag is not passed
if [ "$NO_DELETE" == "false" ]; then
    eval h2o secret delete $SECRET_NAME $CONF_PARAM
fi

# Extract the first key-value pair
FIRST_KEY_VALUE=${KEY_VALUES[0]}

# Create the secret with the first key-value pair
eval h2o secret create $SECRET_NAME --from-literal=${FIRST_KEY_VALUE} $CONF_PARAM

# Build the literals for the update command from the remaining key-value pairs
LITERALS=""
for ((i=1; i<${#KEY_VALUES[@]}; i++)); do
    LITERALS+="--from-literal=${KEY_VALUES[$i]} "
done

# Update the secret with the remaining key-value pairs
eval h2o secret update $SECRET_NAME $LITERALS $CONF_PARAM

echo "Secrets updated successfully for project $PROJECT."
