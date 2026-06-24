#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

BOARD="${1:-uno-wifi-rev2}"
PORT="${2:-/dev/arduino-0}"

case "$BOARD" in
  uno-wifi-rev2)
    FQBN="arduino:megaavr:uno2018"
    SKETCH="/opt/arduino-iot-lab/firmware/uno_wifi_rev2_bme280_pn532"
    ;;
  yun-rev2)
    FQBN="arduino:avr:yun"
    SKETCH="/opt/arduino-iot-lab/firmware/yun_rev2_4g_lte_gps_tether"
    ;;
  arduino-q)
    FQBN="${ARDUINO_Q_FQBN:-arduino:megaavr:uno2018}"
    SKETCH="/opt/arduino-iot-lab/firmware/arduino_q_bmm150_amg8833"
    ;;
  run-rev2)
    FQBN="${RUN_REV2_FQBN:-arduino:megaavr:uno2018}"
    SKETCH="/opt/arduino-iot-lab/firmware/run_rev2_wifi_probe"
    ;;
  *)
    die "Unknown board $BOARD"
    ;;
esac

log "Compile/upload $BOARD FQBN=$FQBN PORT=$PORT"
lxc exec "$LXD_CONTAINER" -- bash -lc "
set -e
arduino-cli compile --fqbn '$FQBN' '$SKETCH'
arduino-cli upload -p '$PORT' --fqbn '$FQBN' '$SKETCH'
"
