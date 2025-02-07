#!/bin/bash

COOKIES="/tmp/cookies.txt"
CURRENT_PORT=""

# Function to update the qbittorrent port
update_port () {
  PORT=$1

  # Clean up cookies file if it exists
  rm -f "$COOKIES"

  # Log in to the qbittorrent web UI and save cookies
  curl -s -c "$COOKIES" --data "username=$QBITTORRENT_USER&password=$QBITTORRENT_PASS" "${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/auth/login" > /dev/null
  if [[ $? -ne 0 ]]; then
    echo "[Error]❌ Login failed."
    return 1
  fi

  # Update qbittorrent preferences with the new port
  curl -s -b "$COOKIES" --data "json={\"listen_port\": \"$PORT\"}" "${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/app/setPreferences" > /dev/null
 # Check current port to see if changes took effect
  CURRENT_PORT=$(curl -s -b $COOKIES ${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/app/preferences | jq -r '.listen_port')

  if [ "$CURRENT_PORT" == "$PORT" ]; then
    echo "[Info] Successfully updated qbittorrent to port $PORT"
    reannounce_all "$COOKIES"
    return 0
  else
    echo "[Error]❌ Failed to update port."
    return 1
  fi

  # Clean up cookies file
  rm -f "$COOKIES"

  echo "[Info]✅ Successfully updated qbittorrent to port $PORT"
}

reannounce_all () {
# Get list of all torrent hashes
  TORRENTS_JSON=$(curl -s -b "$COOKIEs" "${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/torrents/info")
  HASHES=$(echo "$TORRENTS_JSON" | jq -r '.[].hash')

  if [[ -z "$HASHES" ]]; then
      echo "❌ No torrents found!"
      exit 1
  fi

  echo "📂 Found $(echo "$HASHES" | wc -l) torrents. Reannouncing..."

  # Reannounce each torrent
  curl -X POST "${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/torrents/reannounce" \
      --data "hashes=all" \
      -b "$COOKIE_JAR"

echo "✅ All torrents reannounced!"
}

# Main loop to check the port and update if necessary
while true; do
  # Fetch the forwarded port
  PORT_FORWARDED=$(curl -s -H "X-API-Key: ${GLUETUN_APIKEY}" ${HTTP_S}://${GLUETUN_HOST}:${GLUETUN_PORT}/v1/openvpn/portforwarded | awk -F: '{gsub(/[^0-9]/,"",$2); print $2}')
  
  # Check if the fetched port is valid
  if [[ -z "$PORT_FORWARDED" || ! "$PORT_FORWARDED" =~ ^[0-9]+$ ]]; then
    echo "[Error]❌ Failed to retrieve a valid port number, response from Gluetun."
    sleep 10
    continue
  fi
  #echo "Port retreived from Gluetun: $PORT_FORWARDED"
  # If the current port is different from the forwarded port, update it
  if [[ "$CURRENT_PORT" != "$PORT_FORWARDED" ]]; then
    update_port "$PORT_FORWARDED"
  else
    echo "[Info]🟰 Current Gluetun port matches Qbittorrent port."
  fi

  # Wait for a specific interval before checking again
  sleep $RECHECK_TIME
done
