#!/bin/bash

# Function to map words to index positions
map_number_to_index() {
    case "$1" in
        "one") echo 0 ;;
        "two") echo 1 ;;
        "three") echo 2 ;;
        "four") echo 3 ;;
        "five") echo 4 ;;
        "six") echo 5 ;;
        "seven") echo 6 ;;
        "eight") echo 7 ;;
        "nine") echo 8 ;;
        "ten") echo 9 ;;
        "all") echo "all" ;;
        *) echo -1 ;;
    esac
}

# Get the list of APP_IDs
app_ids=($(h2o instance list | awk 'NR>1 {print $1}'))

# Loop through the arguments
for arg in "$@"
do
    index=$(map_number_to_index "$arg")
    
    if [[ "$index" == "all" ]]; then
        # Terminate all instances
        for app_id in "${app_ids[@]}"; do
            echo "Terminating instance $app_id..."
            h2o instance terminate "$app_id"
        done
        break  # No need to process further arguments after "all"
    elif [[ "$index" -ge 0 && "$index" -lt "${#app_ids[@]}" ]]; then
        app_id=${app_ids[$index]}
        echo "Terminating instance $app_id..."
        h2o instance terminate "$app_id"
    else
        echo "Invalid argument or out of range: $arg"
    fi
done
