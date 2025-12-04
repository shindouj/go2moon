#!/bin/bash

GO2MOON_PATH="${HOME}/go2rtc"
GO2MOON_CONFIG_PATH="${GO2MOON_PATH}/go2rtc.yaml"
GO2MOON_USER=$USER
MOONRAKER_CONFIG="${HOME}/printer_data/config/moonraker.conf"
SERVICE_CONFIG="${HOME}/printer_data/moonraker.asvc"
SYSTEMDDIR="/etc/systemd/system"

function preflight_checks {
    if [ "$EUID" -eq 0 ]; then
        echo "[PRE-CHECK] This script must not be ran as root!\n"
        exit 255
    fi
}

function get_go2rtc_binary {
    local system_arch
    system_arch="$(uname -m)"

    case $system_arch in 

    aarch64 | aarch64_be)
        echo "go2rtc_linux_arm64"
        ;;
    
    x86_64)
        echo "go2rtc_linux_amd64"
        ;;

    arm | armv7l | armv7b | armv8b | armv8l)
        echo "go2rtc_linux_arm"
        ;;
    
    armv6l | armv6b)
        echo "go2rtc_linux_armv6"
        ;;

    esac
}

function check_download {
    if [ ! -d "${GO2MOON_PATH}" ]; then
        echo "[DOWNLOAD] Downloading latest go2rtc release...\n"
        if wget -q --show-progress https://github.com/shindouj/go2moon/releases/latest/download/go2rtc.zip -P "$GO2MOON_PATH"; then
            unzip "$GO2MOON_PATH/go2rtc.zip" -d "$GO2MOON_PATH"
            chmod +x "$GO2MOON_PATH"/go2rtc_linux_*
            rm "$GO2MOON_PATH/go2rtc.zip"
        else
            printf "[DOWNLOAD] Error: failed to download newest release.\n" 
        fi
    else
        printf "[DOWNLOAD] go2rtc already found locally. Continuing...\n\n"
    fi
}

function add_updater {
    update_section=$(grep -c '\[update_manager[a-z ]* go2rtc\]' "$MOONRAKER_CONFIG" || true)
    if [ "$update_section" -eq 0 ]; then
        echo -n "[INSTALL] Adding update manager to moonraker.conf..."
        cat <<EOF >>"$MOONRAKER_CONFIG"

## go2rtc automatic update management
[update_manager go2rtc]
type: zip
repo: shindouj/go2moon
path: ~/go2rtc
primary_branch: main
managed_services: go2rtc
EOF
    fi
}

function create_default_config {
    if [ ! -f "${GO2MOON_CONFIG_PATH}" ]; then
        echo -n "[INSTALL] Creating default config file...\n"
        cat > "${GO2MOON_CONFIG_PATH}" << EOF
api:
  listen: ":1984"
  origin: "*"

ffmpeg:
  bin: "ffmpeg"

log:
  format: "color"
  level: "info"
  output: "stdout"
  time: "UNIXMS"

rtsp:
  listen: ":8554"
  default_query: "video"

srtp:
  listen: ":8443"

webrtc:
  listen: ":8555/tcp"
  ice_servers:
    - urls: [ "stun:stun.l.google.com:19302" ]
EOF
    fi
}

function create_service {
    if [ ! -f "${SYSTEMDDIR}"/go2rtc.service ]; then
        echo -n "[INSTALL] Adding system service...\n"
        sudo /bin/sh -c "cat > $SYSTEMDDIR/go2rtc.service" << EOF
[Unit]
Description=Video transcoder using go2rtc
Documentation=https://go2rtc.com/ https://github.com/AlexxIT/go2rtc
After=network-online.target
Requisite=network-online.target

[Service]
Type=exec
ExecStart=$HOME/go2rtc/$(get_go2rtc_binary) --config $HOME/go2rtc/go2rtc.yaml
Environment="PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"
Restart=always
RestartSec=5
User=$GO2MOON_USER

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl enable go2rtc.service
        sudo systemctl start go2rtc.service
    fi
    
    go2moon_line=$(grep -c 'go2rtc' "$SERVICE_CONFIG" || true)
    if [ "$go2moon_line" -eq 0 ]; then
        echo -n "[INSTALL] Adding go2rtc service to moonraker.asvc...\n"
        echo "go2rtc" >> "$SERVICE_CONFIG"
    fi
}

function install_ffmpeg {
    echo -n "[INSTALL] Installing ffmpeg...\n"
    sudo apt-get -qq -y install ffmpeg
}

function restart_moonraker {
    echo "[POST-INSTALL] Restarting Moonraker...\n"
    sudo systemctl restart moonraker
}

preflight_checks
install_ffmpeg
check_download
create_default_config
add_updater
create_service
restart_moonraker
