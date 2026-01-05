#!/bin/sh
set -eu

echo "[axedgb] DGB entrypoint starting"

if ! command -v digibyted >/dev/null 2>&1; then
  echo "[axedgb] ERROR: digibyted not found in PATH"
  exit 127
fi

extra=""
if [ -f /data/.reindex-chainstate ]; then
  echo "[axedgb] Reindex requested (chainstate)."
  rm -f /data/.reindex-chainstate || true
  extra="-reindex-chainstate"
fi

dbcache="${DGB_DBCACHE_MB:-}"
if [ -z "$dbcache" ] && [ -r /proc/meminfo ]; then
  mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)"
  if [ -n "$mem_kb" ]; then
    if [ "$mem_kb" -le 1048576 ]; then
      dbcache="128"
    elif [ "$mem_kb" -le 2097152 ]; then
      dbcache="256"
    elif [ "$mem_kb" -le 4194304 ]; then
      dbcache="512"
    elif [ "$mem_kb" -le 8388608 ]; then
      dbcache="1024"
    else
      dbcache="2048"
    fi
  fi
fi

if [ -n "$dbcache" ]; then
  extra="$extra -dbcache=$dbcache"
fi

echo "[axedgb] Exec: digibyted -datadir=/data -printtoconsole $extra"
exec digibyted -datadir=/data -printtoconsole $extra
