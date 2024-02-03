#!/bin/bash
output_file="/Users/lennoxomondi/speedtest/ping_log.json" # Update with the desired file path

# Get the default route's interface
if ! default_interface=$(/sbin/route get default | grep interface | awk '{print $2}'); then
    exit 1
fi
# Determine the connection type based on the interface
case "$default_interface" in
    en0)
        connection_type="LAN"
        ;;
    en2* | bridge*)
        connection_type="iPhone USB"
        echo "existing because the connection is Data"
        #Exit if the connection is in tethermoda
        exit 1
        ;;
    en1)
        connection_type="WiFi"
        exit 1
        ;;
    *)
        connection_type="Unknown"
        exit 1
        ;;
esac

for i in {1..60}; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    ping_output=$(/sbin/ping -c 1 8.8.8.8 2>&1 | /usr/local/bin/jq -sR )
#    echo "{\"response\": $ping_output}" >>"$output_file";
    if [[ $ping_output == *"1 packets transmitted, 1 packets received"* ]]; then
        # Successful ping
        ping_ms=$( echo "$ping_output" | grep "time=")
        echo "{\"timestamp\":\"$timestamp\",\"ping\":$ping_ms}," >> "$output_file"
    else
      # Ping failed
        echo "{\"timestamp\":\"$timestamp\",\"error\":$ping_output}," >> "$output_file"
    fi

    sleep 1
done
