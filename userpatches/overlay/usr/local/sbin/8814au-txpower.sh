#!/bin/sh
# Fija TX power a 13 dBm en el adaptador USB de auditoria.
# Se lanza por udev cuando aparece la interfaz; espera al rename de 10-wlx40.link.
logger -t 8814au-txpower "Iniciando; esperando wlx40"
i=0
while [ "$i" -lt 120 ]; do
  if [ -d /sys/class/net/wlx40 ]; then
    IW=$(command -v iw 2>/dev/null || echo /sbin/iw)
    if "$IW" dev wlx40 set txpower fixed 1300 2>/dev/null; then
      logger -t 8814au-txpower "TX power fijado a 13 dBm en wlx40"
      exit 0
    fi
    logger -t 8814au-txpower "wlx40 presente pero no se pudo fijar TX power"
    exit 1
  fi
  sleep 0.5
  i=$((i+1))
done
# Adaptador desconectado: estado normal, no es un fallo
logger -t 8814au-txpower "Adaptador wlx40 no conectado; TX power no aplicado"
exit 0
