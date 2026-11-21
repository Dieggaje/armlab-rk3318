# ArmLab WiFi · RK3318

Imagen personalizada de Armbian para **RK3318 TV Box** con escritorio monitorizado y herramientas de auditoría WiFi. Elaborada a partir del sistema instalado en el box original, pero **sanitizada** para poder compartirla.

## Qué contiene

- **Armbian Trixie + XFCE**, kernel `current`, placa `rk3318-box`.
- **Logo previo al escritorio** (`RK3318 · ArmLab WiFi · by DieGGaje`, 6 s).
- **Widget Conky** en español: fecha, hora, temperatura, CPU, RAM, disco, carga, tiempo y localidad (una sola llamada a `wttr.in` cada 10 min).
- **Menú `sudo lab`** con 12 opciones y ancho de 60 columnas.
- **Pack de auditoría**: `nmap`, `tcpdump`, `tshark`, `john`, `crunch`, `hcxdumptool`, `hcxtools`, `aircrack-ng`, `kismet`, `reaver`, `bully`, `hashcat`, `lynis`, `bettercap` (si está disponible), más `airgeddon` y `wifite2` en `/opt/armlab/auditoria-wifi`.
- **Driver DKMS `rtl8814au` 5.8.5.1** para el dongle USB Realtek `0bda:8813`.
- **Servicios propios**: bootsplash, gobernador `performance`, subida de `wlx40`, guardia del driver y potencia TX 13 dBm.
- **Ajustes**: idioma/teclado `es`, zona `Europe/Madrid`, zram `lz4`, swapfile de 2 G, `swappiness=60`, root `noatime`, montaje opcional de SD por etiqueta `ARMLAB_SD`.
- PulseAudio se conserva: quitarlo dejaría sin sonido los vídeos y las apps.

## Qué se ha eliminado (sanitización)

| Dato | Estado |
|---|---|
| Contraseñas WiFi/SSH/sudo | **No incluidas**. El primer arranque las pide. |
| IP fija del box original | **Eliminada**. Red por DHCP. |
| Claves SSH del host, `known_hosts`, historial | **No incluidos**. |
| Usuario SSH original y sus rutas | Sustituido por `diego` y `/var/lib/armlab`, `/opt/armlab`. |
| MAC del dongle original | Sustituida por coincidencia por driver `rtl8814au`. |
| Capturas, wordlists, reportes, `authorized.txt` | **No incluidos**. |
| Ubicación exacta del widget | Cambiada a `Galicia, España` (configurable con `WEATHER_LOC`). |
| Firma `by DieGGaje` | **Conservada** (es la marca del proyecto). |

## Cómo compilar

1. Crea un repositorio en GitHub (puede ser público) y sube **todo** el contenido de esta carpeta.
2. Entra en **Actions → ArmLab WiFi · RK3318 → Run workflow**.
3. Espera 20–60 min (compilar el kernel tarda).
4. En **Releases** descarga `Armbian_unofficial_..._RK3318_Box_trixie_current_xfce.img.xz`.

No necesitas Docker, WSL ni 50 GB libres en tu PC: GitHub compila por ti. El plan gratuito da 2000 min/mes, suficiente para varias pruebas.

### Compilar en local (opcional)

En un equipo x86_64 con Debian 13, Docker y ~50 GB libres:

```bash
git clone https://github.com/armbian/build.git
cd build
mkdir -p userpatches
cp -a /ruta/este/repo/userpatches/. userpatches/
./compile.sh armlab
```

## Cómo instalar

1. Graba la imagen en una **microSD** con BalenaEtcher (o `dd`).
2. Arranca el box desde la SD **antes de tocar el eMMC**.
3. El primer arranque pregunta usuario (`diego`), contraseñas e idioma. Elige tus propias contraseñas.
4. Comprueba `sudo lab`, el logo, el widget y que `wlan0` sigue recibiendo DHCP.
5. Si todo funciona y quieres migrar al eMMC, hazlo con `dd` desde la SD ya configurada.

## Requisitos de hardware

- **RK3318 auténtico** con eMMC y DTB `rockchip/rk3318-box.dtb`. No sirve para RK3328/RK3399 genéricos.
- **Dongle USB RTL8814AU** (`0bda:8813`). Sin él no hay modo monitor; el menú seguirá funcionando pero las opciones de auditoría no.
- El módulo DKMS se compila contra el kernel que genere el build. Si el kernel cambia, se recompila automáticamente por DKMS.

## Estructura

```
.github/workflows/build.yml     Acción de compilación
userpatches/
  config-armlab.conf            Parámetros del build
  customize-image.sh            Instalación de paquetes y ajustes dentro del rootfs
  firstboot.conf                Primer arranque sin secretos
  overlay/                      Archivos copiados tal cual al rootfs
    usr/local/bin/              menú lab y lanzadores
    usr/local/sbin/             scripts propios
    etc/systemd/system/         servicios
    etc/udev/rules.d/           reglas del dongle (sin MAC)
    opt/armlab/auditoria-wifi/  airgeddon + wifite2
    usr/src/rtl8814au-5.8.5.1/ fuente DKMS limpia
    home/diego/                 Conky y configuración XFCE
```

## Notas legales

Esta imagen es para **auditoría de redes propias o con autorización explícita**. El menú no incluye guardias ni avisos: el usuario es responsable de su uso.

`by DieGGaje`
