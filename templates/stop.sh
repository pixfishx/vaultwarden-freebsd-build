#!/bin/sh
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

stop_pid() {
  PID="$1"
  # 发送 SIGTERM 优雅停止
  kill "$PID" 2>/dev/null || true
  # 最多等 10 秒，仍未退出则强杀
  i=0
  while kill -0 "$PID" 2>/dev/null && [ "$i" -lt 10 ]; do
    i=$((i + 1))
    sleep 1
  done
  if kill -0 "$PID" 2>/dev/null; then
    kill -9 "$PID" 2>/dev/null || true
    echo "Vaultwarden force-killed (PID $PID)"
  else
    echo "Vaultwarden stopped (PID $PID)"
  fi
}

if [ -f "$DIR/vaultwarden.pid" ]; then
  PID="$(cat "$DIR/vaultwarden.pid" 2>/dev/null || true)"
  rm -f "$DIR/vaultwarden.pid"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    stop_pid "$PID"
  else
    echo "No running process found (stale pid file removed)"
  fi
else
  # 无 pid 文件时按进程名兜底
  PIDS="$(pgrep -f "$DIR/vaultwarden" 2>/dev/null || true)"
  if [ -n "$PIDS" ]; then
    for PID in $PIDS; do stop_pid "$PID"; done
  else
    echo "Vaultwarden not running"
  fi
fi
