#!/bin/sh
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

echo "Process:"
ps aux | grep vaultwarden | grep -v grep || echo "  (no vaultwarden process found)"

echo
echo "Local HTTP:"
PORT="$(grep '^ROCKET_PORT=' .env 2>/dev/null | cut -d= -f2)"
PORT="${PORT:-12080}"
if curl -s -I "http://127.0.0.1:$PORT" 2>/dev/null | head -n 1; then
  :
else
  echo "  no response on 127.0.0.1:$PORT"
fi

echo
echo "PID file:"
if [ -f "$DIR/vaultwarden.pid" ]; then
  echo "  $(cat "$DIR/vaultwarden.pid" 2>/dev/null || echo empty)"
else
  echo "  (none)"
fi

echo
echo "Recent log:"
tail -n 20 "$DIR/logs/vaultwarden.log" 2>/dev/null || echo "  (no log yet)"
