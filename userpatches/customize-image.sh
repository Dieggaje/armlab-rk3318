#!/usr/bin/env bash
# ArmLab WiFi: personalizacion de la imagen.
# Se ejecuta DENTRO del rootfs de destino (chroot), justo antes de cerrar la imagen.
set -e
export DEBIAN_FRONTEND=noninteractive

echo "[ArmLab] Copiando overlay..."
cp -a /tmp/overlay/. /

# Git en Windows no conserva el bit ejecutable; lo reponemos aquí.
chmod +x /usr/local/bin/* /usr/local/sbin/armlab-* /usr/local/sbin/8814au-* \
         /etc/update-motd.d/05-armlab 2>/dev/null || true

# Dotfiles del escritorio para cualquier usuario que cree el asistente de primer arranque.
mkdir -p /etc/skel
cp -a /tmp/overlay/home/diego/. /etc/skel/
rm -rf /home/diego

echo "[ArmLab] Idioma, teclado y zona horaria..."
locale-gen es_ES.UTF-8 >/dev/null 2>&1 || true
update-locale LANG=es_ES.UTF-8 LC_ALL=es_ES.UTF-8 || true
printf 'Europe/Madrid\n' > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime

echo "[ArmLab] Nombre de equipo..."
printf 'armlab-rk3318\n' > /etc/hostname
sed -i 's|^127\.0\.1\.1.*|127.0.1.1\tarmlab-rk3318|' /etc/hosts || true

echo "[ArmLab] Instalando pack de auditoria..."
apt-get update -qq
CORE="nmap tcpdump tshark john crunch hcxdumptool hcxtools aircrack-ng reaver bully hashcat kismet lynis figlet conky whiptail macchanger dkms build-essential curl git python3 net-tools wireless-tools iw"
apt-get install -y --no-install-recommends $CORE
# Opcionales: si no estan en el repositorio, no rompen el build.
apt-get install -y --no-install-recommends bettercap || echo "[ArmLab] AVISO: bettercap no disponible en este repositorio"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[ArmLab] Compilando driver RTL8814AU (DKMS)..."
KVER=$(basename "$(ls -d /lib/modules/* 2>/dev/null | head -1)")
if [ -n "$KVER" ] && [ -d "/lib/modules/$KVER/build" ]; then
    dkms add -m rtl8814au -v 5.8.5.1 >/dev/null 2>&1 || true
    dkms build -m rtl8814au -v 5.8.5.1 -k "$KVER" || echo "[ArmLab] AVISO: fallo el build de DKMS"
    dkms install -m rtl8814au -v 5.8.5.1 -k "$KVER" || echo "[ArmLab] AVISO: fallo el install de DKMS"
    depmod -a "$KVER" || true
else
    echo "[ArmLab] AVISO: sin headers en build; DKMS recompilara en el primer arranque"
fi

echo "[ArmLab] Swap, fstab y directorios..."
mkdir -p /mnt/armlab-sd /var/lib/armlab/wordlists /root/capturas_wifi
chmod 0777 /var/lib/armlab/wordlists
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile >/dev/null

# root sin atime (menos escrituras en eMMC)
sed -i -E 's|^([[:space:]]*UUID=[^[:space:]]+[[:space:]]+/[[:space:]]+ext4[[:space:]]+)defaults|\1noatime|' /etc/fstab || true
grep -q '/swapfile' /etc/fstab || printf '/swapfile none swap sw,pri=1 0 0\n' >> /etc/fstab
grep -q 'ARMLAB_SD' /etc/fstab || printf 'LABEL=ARMLAB_SD /mnt/armlab-sd ext4 defaults,noatime,nofail,x-systemd.device-timeout=10 0 2\n' >> /etc/fstab

echo "[ArmLab] Parametros de arranque USB..."
if [ -f /boot/armbianEnv.txt ]; then
    if grep -q '^extraargs=' /boot/armbianEnv.txt; then
        sed -i 's|^extraargs=|extraargs=usbcore.autosuspend=-1 |' /boot/armbianEnv.txt
    else
        printf 'extraargs=usbcore.autosuspend=-1\n' >> /boot/armbianEnv.txt
    fi
    grep -q '^usbstoragequirks=' /boot/armbianEnv.txt || \
        printf 'usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u\n' >> /boot/armbianEnv.txt
fi

echo "[ArmLab] Habilitando servicios..."
systemctl enable armlab-bootsplash.service armlab-cpu-performance.service \
    armlab-wlx40-up.service 8814au-guard.service 8814au-txpower.service 2>/dev/null || true

echo "[ArmLab] Script de aprovisionamiento del primer arranque..."
cat > /root/provisioning.sh <<'EOS'
#!/bin/bash
# Se ejecuta una vez tras el primer login correcto.
set -e
U=diego
id -u "$U" >/dev/null 2>&1 || exit 0
chown -R "$U:$U" "/home/$U/.conkyrc" "/home/$U/.config" "/home/$U/.local" 2>/dev/null || true
chown -R "$U:$U" /var/lib/armlab/wordlists 2>/dev/null || true
echo "[ArmLab] escritorio listo para $U"
EOS
chmod +x /root/provisioning.sh

echo "[ArmLab] Personalizacion terminada."
