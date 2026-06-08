#!/bin/bash

# wifi-reconnect.sh
# Attempts to reconnect to WiFi on Raspberry Pi using nmcli

PING_HOST="${1:-8.8.8.8}"   # Target to ping (default: Google DNS)
MAX_ATTEMPTS=5               # How many reconnect attempts before giving up
RETRY_DELAY=10               # Seconds between attempts

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

is_connected() {
  ping -c 1 -W 3 "$PING_HOST" &>/dev/null
}

reconnect() {
  local iface
  iface=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')

  if [[ -z "$iface" ]]; then
    log "ERROR: No WiFi interface found."
    return 1
  fi

  log "Attempting reconnect on interface: $iface"
  nmcli device disconnect "$iface" &>/dev/null
  sleep 2
  nmcli device connect "$iface"
}

# --- Main ---

log "--- WiFi reconnect check started ---"

if is_connected; then
  log "Already connected. Nothing to do."
  exit 0
fi

log "No connectivity detected. Starting reconnect loop..."

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  log "Attempt $attempt of $MAX_ATTEMPTS..."

  reconnect

  sleep "$RETRY_DELAY"

  if is_connected; then
    log "Reconnected successfully on attempt $attempt."
    exit 0
  else
    log "Still no connectivity."
  fi
done

log "FAILED: Could not reconnect after $MAX_ATTEMPTS attempts."
exit 1