#!/bin/sh
set -eu

DATADIR="${DATADIR:-/data}"
FLAG="${DATADIR}/sync_enabled"

read_flag() {
  if [ -f "${FLAG}" ]; then
    # Accept "1", "true", etc. Anything else is treated as off.
    val="$(head -n 1 "${FLAG}" 2>/dev/null | tr -d '\r\n\t ' || true)"
    case "${val}" in
      1|true|TRUE|yes|YES|on|ON) echo 1 ;;
      *) echo 0 ;;
    esac
  else
    echo 0
  fi
}

start_node() {
  echo "[fractald] Starting Fractal node..."
  bitcoind -datadir="${DATADIR}" -printtoconsole &
  echo $! > /tmp/bitcoind.pid
}

stop_node() {
  if [ ! -f /tmp/bitcoind.pid ]; then
    return
  fi
  pid="$(cat /tmp/bitcoind.pid 2>/dev/null || true)"
  if [ -z "${pid}" ]; then
    rm -f /tmp/bitcoind.pid || true
    return
  fi

  echo "[fractald] Stopping Fractal node..."
  bitcoin-cli -datadir="${DATADIR}" stop >/dev/null 2>&1 || true

  # Wait up to ~30s, then force-kill.
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if ! kill -0 "${pid}" 2>/dev/null; then
      rm -f /tmp/bitcoind.pid || true
      return
    fi
    sleep 2
  done

  kill "${pid}" 2>/dev/null || true
  rm -f /tmp/bitcoind.pid || true
}

while true; do
  if [ "$(read_flag)" = "1" ]; then
    start_node
    pid="$(cat /tmp/bitcoind.pid 2>/dev/null || true)"
    while [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; do
      if [ "$(read_flag)" != "1" ]; then
        stop_node
        break
      fi
      sleep 5
    done
  else
    echo "[fractald] Fractal sync disabled (toggle AxePoW mode in the app to enable)."
    sleep 10
  fi
done
