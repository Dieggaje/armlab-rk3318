#!/bin/sh
# Restaura el modulo 8814au si el .ko quedo vacio por un corte de corriente
LOG=/var/log/8814au-guard.log
GOOD=/root/wifi-driver/8814au.ko.good
EXP=/root/wifi-driver/expected.md5
KVERFILE=/root/wifi-driver/kernel.txt
KVER=$(uname -r)
KO=/lib/modules/$KVER/updates/dkms/8814au.ko

[ -s "$GOOD" ] || exit 0
[ -f "$EXP" ] || exit 0

EXPECTED=$(tr -d " \n" < "$EXP")
ACTUAL=$(md5sum "$GOOD" | cut -d" " -f1)
if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "$(date) backup corrupto, no restauro" >> "$LOG"
  exit 0
fi

if [ -f "$KVERFILE" ] && [ "$(cat "$KVERFILE")" != "$KVER" ]; then
  echo "$(date) kernel distinto ($KVER), no restauro" >> "$LOG"
  exit 0
fi

if [ ! -s "$KO" ]; then
  echo "$(date) $KO vacio o ausente -> restaurando" >> "$LOG"
  mkdir -p "$(dirname "$KO")"
  cp -f "$GOOD" "$KO"
  chmod 644 "$KO"
  depmod -a "$KVER" >> "$LOG" 2>&1
  sync
fi

modprobe 8814au >> "$LOG" 2>&1 || true
exit 0
