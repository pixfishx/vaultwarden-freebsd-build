#!/bin/sh
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

# 二进制必须存在
if [ ! -x "$DIR/vaultwarden" ]; then
  echo "ERROR: 未找到 $DIR/vaultwarden" >&2
  exit 1
fi

# 加载 .env（不存在则提示）
if [ -f ./.env ]; then
  set -a; . ./.env; set +a
else
  echo "WARNING: 未找到 .env，请先 cp .env.example .env 并填写" >&2
fi

# 运行环境：优先自带 lib/，系统库兜底
export LD_LIBRARY_PATH="$DIR/lib:/usr/local/lib:/usr/lib:/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# 默认值兜底（.env 未设置时）
: "${ROCKET_ADDRESS:=127.0.0.1}"
: "${ROCKET_PORT:=12080}"
: "${DATA_FOLDER:=$DIR/data}"

mkdir -p "$DATA_FOLDER" "$DIR/logs"

# 已在运行则直接退出
if [ -f "$DIR/vaultwarden.pid" ]; then
  OLD_PID="$(cat "$DIR/vaultwarden.pid" 2>/dev/null || true)"
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "Vaultwarden already running, PID: $OLD_PID"
    exit 0
  fi
fi

nohup "$DIR/vaultwarden" > "$DIR/logs/vaultwarden.log" 2>&1 &
NEW_PID=$!
echo $NEW_PID > "$DIR/vaultwarden.pid"

# 等 2 秒确认进程存活（启动即崩溃时报错而不是假装成功）
sleep 2
if ! kill -0 "$NEW_PID" 2>/dev/null; then
  echo "ERROR: Vaultwarden 启动后立即退出，请查看日志:" >&2
  tail -n 20 "$DIR/logs/vaultwarden.log" >&2 || true
  rm -f "$DIR/vaultwarden.pid"
  exit 1
fi

echo "Vaultwarden started, PID: $NEW_PID"
echo "LOG: $DIR/logs/vaultwarden.log"
