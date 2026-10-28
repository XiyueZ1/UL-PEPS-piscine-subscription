#!/bin/bash
# 生成订阅用的日历文件。
# 程序来自原仓库 XiyueZ1/UL-PEPS-piscine-calendar，这里不改动它，只调用它。
#
# 用法: bash build.sh <程序路径> <网页文件> <输出文件夹>
set -euo pipefail

TOOL="$1"
PAGE="$2"
OUT="$3"
mkdir -p "$OUT"

# 生成一个日历: make <文件名> <日历名称> [程序选项...]
make() {
  local file="$1" name="$2"
  shift 2
  local path="$OUT/$file"
  local msg
  if msg=$(python "$TOOL" --file "$PAGE" --out "$path" "$@" 2>&1); then
    echo "$msg"
  elif echo "$msg" | grep -q "没有符合条件的时段"; then
    # 这次筛选没有时段（比如某两周没有家庭场）。生成一个空日历，订阅不会中断。
    echo "$file: 没有时段，生成空日历"
    printf 'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//peps-piscine//FR\r\nCALSCALE:GREGORIAN\r\nX-WR-CALNAME:PEPS piscine\r\nX-WR-TIMEZONE:America/Toronto\r\nEND:VCALENDAR\r\n' > "$path"
  else
    # 其他错误（比如官网改版，找不到课表）：直接失败，网上保持上一版日历不变
    echo "$msg" >&2
    exit 1
  fi
  # 改成每个日历自己的名字，并建议日历软件每天检查一次更新
  sed -i \
    -e "s|^X-WR-CALNAME:.*\r\$|X-WR-CALNAME:${name}\r|" \
    -e "s|^\(X-WR-TIMEZONE:.*\)\r\$|\1\r\nREFRESH-INTERVAL;VALUE=DURATION:P1D\r\nX-PUBLISHED-TTL:P1D\r|" \
    "$path"
}

make laps.ics      "PEPS piscine"
make olympic.ics   "PEPS piscine olympique" --pool olympique
make diving.ics    "PEPS piscine avec tremplins" --pool tremplins
make 25m-plus.ics  "PEPS piscine 25m+"      --min-length 25
make 50m.ics       "PEPS piscine 50m"       --length 50
make family.ics    "PEPS bains pour tous"   --type tous

TZ=America/Toronto date +"%Y-%m-%d %H:%M %Z" > "$OUT/last-update.txt"
