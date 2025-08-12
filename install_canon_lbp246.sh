#!/bin/bash

set -e  # Exit if any command fails
LOGFILE="canon_install_$(date +%Y-%m-%d_%H-%M-%S).log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOGFILE"
}

DRIVER_URL="https://raw.githubusercontent.com/rathodmanojkumar/Storage_Files/main/linux-UFRII-drv-v610-m17n-03.tar.gz"
TARGET_DIR="$HOME/linux-UFRII-drv-v610-m17n-03"
TAR_NAME="linux-UFRII-drv-v610-m17n-03.tar.gz"
PRINTER_NAME="Canon_LBP246dw"

log "🚀 Starting Canon LBP 246dw driver installation"

# 1. Install dependencies
log "📦 Installing required packages..."
sudo apt update -y | tee -a "$LOGFILE"
sudo apt install -y libcups2 cups printer-driver-gutenprint csh libjpeg62-turbo avahi-utils system-config-printer | tee -a "$LOGFILE"

# 2. Enable and start CUPS
log "🖨 Enabling CUPS service..."
sudo systemctl enable cups
sudo systemctl start cups

# 3. Download driver archive
log "⬇ Downloading Canon driver..."
wget -q --show-progress -O "$TAR_NAME" "$DRIVER_URL" 2>&1 | tee -a "$LOGFILE"

# 4. Extract driver
log "📂 Extracting driver package..."
mkdir -p "$TARGET_DIR"
tar -xzf "$TAR_NAME" -C "$(dirname "$TARGET_DIR")" | tee -a "$LOGFILE"

# 5. Install driver via Canon's install.sh with full permissions
log "⚙ Giving full permissions to Canon install.sh..."
chmod 777 "$TARGET_DIR/install.sh"
log "⚙ Running Canon install.sh..."
( cd "$TARGET_DIR" && sudo ./install.sh ) | tee -a "$LOGFILE"

# 6. Detect printer on network or USB
log "🔍 Detecting Canon printer..."
PRINTER_URI=$(lpinfo -v | grep -i 'Canon' | grep -i 'LBP' | head -n 1 | awk '{print $2}')

if [ -n "$PRINTER_URI" ]; then
    log "✅ Found printer URI: $PRINTER_URI"
    sudo lpadmin -p "$PRINTER_NAME" -E -v "$PRINTER_URI" -m everywhere
    sudo lpoptions -d "$PRINTER_NAME"
    log "✅ Printer '$PRINTER_NAME' installed and set as default"
else
    log "⚠ No Canon LBP printer detected automatically — you may need to add it manually."
fi

# 7. Restart CUPS so printer shows in settings
log "🔄 Restarting CUPS..."
sudo systemctl restart cups

# 8. Open Printer Settings (GNOME/KDE)
if command -v gnome-control-center &> /dev/null; then
    log "📂 Opening GNOME Printer Settings..."
    nohup gnome-control-center printers >/dev/null 2>&1 &
elif command -v system-config-printer &> /dev/null; then
    log "📂 Opening System Config Printer..."
    nohup system-config-printer >/dev/null 2>&1 &
else
    log "⚠ Could not find printer settings app. Install with: sudo apt install system-config-printer"
fi

log "🎉 Canon driver installation completed! Check Ubuntu Printer Settings to confirm."
