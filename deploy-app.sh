#!/bin/bash

# Default values
visibility=""
service_account=""

# Parse arguments
while getopts "v:a:" opt; do
  case $opt in
    v)
      if [ "$OPTARG" == "ALL" ]; then
        visibility="-v ALL_USERS"
      fi
      ;;
    a)
      case $OPTARG in
        dev-mcci)
          service_account="hadc-7342183-wave-mcci-sa"
          ;;
        int-mcci)
          service_account="hadc-7342185-wave-mcci-sa"
          ;;
        dev-mcac)
          service_account="hadc-7342183-wave-mcac-sa"
          ;;
        int-mcac)
          service_account="hadc-7342185-wave-mcac-sa"
          ;;
        *)
          echo "Error: Invalid service account option '$OPTARG'."
          exit 1
          ;;
      esac
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# Ensure a service account was provided
if [ -z "$service_account" ]; then
  echo "Error: Service account not specified. Use -a to specify it."
  exit 1
fi

# Run h2o bundle import -g with visibility if specified
output=$(h2o bundle import -g $visibility)

# Extract the ID from the output using awk
app_id=$(echo "$output" | awk '/^ID/ {print $2}')

# Check if the ID was extracted successfully
if [ -z "$app_id" ]; then
  echo "Error: Could not extract the app ID."
  exit 1
fi

# Set the service account
h2o admin app set-service-account "$app_id" "$service_account"

# Check if the service account was set successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to set service account."
  exit 1
fi

# Run the app and capture the output
run_output=$(h2o app run "$app_id")

# Print the output to the terminal
echo "$run_output"

# Check if the app ran successfully
if [ $? -eq 0 ]; then
  echo "App is running successfully."
else
  echo "Error: Failed to run the app."
  exit 1
fi

# Extract the URL from the run command output
url=$(echo "$run_output" | awk '/^URL/ {print $2}')

# Open the URL in the default web browser
if [ -n "$url" ]; then
  open "$url"
else
  echo "Error: Could not extract the URL."
fi
