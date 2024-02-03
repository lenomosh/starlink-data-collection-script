#!/bin/bash
# Function to check if a command exists
command_exists() {
  type "$1" &>/dev/null
}
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

file_path="/Users/lennoxomondi/speedtest/speedtest_weather_ping_log.json"
# Ensure required commands are available
if ! command_exists /usr/local/bin/speedtest || ! command_exists /usr/bin/curl || ! command_exists /sbin/ping || ! command_exists /sbin/route; then
  exit 1
fi
speedtest_error=""

# Perform Speedtest
if ! speedtest_output=$(/usr/local/bin/speedtest -f json); then
  speedtest_error=$("Error: Speedtest failed:  $speedtest_output" | /usr/local/bin/jq -sR)
fi


# Get Weather Data
api_key=""
weather_error="Error: "
if ! weather_output=$(/usr/bin/curl -s "https://api.openweathermap.org/data/2.5/weather?lat=-0.8058&lon=34.6283&appid=$api_key"); then
  weather_error=$("Failed to fetch weather data: $weather_output" | /usr/local/bin/jq -sR)
fi

# Current Timestamp
timestamp=$(date +"%Y-%m-%d %H:%M:%S")



#check if error exists
if [ -z "$weather_error" ]|| [ -z "$speedtest_error" ]; then
  echo "{\"timestamp\":\"$timestamp\",\"connection_type\":\"$connection_type\",\"weather\":$weather_output,\"speedtest\":$speedtest_output}," >> "$file_path";
else
  echo "{\"timestamp\":\"$timestamp\",\"weather_error\":$($weather_error | /usr/local/bin/jq -sR),\"speedtest_error\":$($speedtest_error | /usr/local/bin/jq -sR)},">> "$file_path"
fi