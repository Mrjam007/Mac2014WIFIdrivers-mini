#!/bin/bash
# Broadcom Wi-Fi Driver Installer for Mac Mini 7,1 (BCM4360)
# For Ubuntu 24.04 (Noble) and derivatives

set -euo pipefail  # Exit on error, undefined variables, and pipeline failures

# Initialize PROPOSED_FILE early so the trap can always reference it safely
PROPOSED_FILE=""

# Guarantee repo cleanup even if the script crashes
trap '[ -n "$PROPOSED_FILE" ] && rm -f "$PROPOSED_FILE"; apt update' EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Broadcom Wi-Fi Driver Installer for Mac Mini 7,1 ===${NC}"
echo "This script will install the proprietary Broadcom driver (wl) for your BCM4360."
echo "You need an active internet connection (use a USB Wi-Fi adapter or Ethernet)."

# Check root privileges
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo).${NC}"
    exit 1
fi

# Detect BCM4360 via PCI ID (14e4:43a0)
if ! lspci -nn | grep -qi "14e4:43a0"; then
    echo -e "${RED}BCM4360 (14e4:43a0) not detected. Exiting.${NC}"
    exit 1
fi

# Check internet connectivity
echo -e "${YELLOW}Checking internet connection...${NC}"
if ! curl -fsI http://archive.ubuntu.com > /dev/null; then
    echo -e "${RED}No internet connection. Please connect via USB adapter or Ethernet and try again.${NC}"
    exit 1
fi

# Detect OS codename dynamically
UBUNTU_CODENAME=$(source /etc/os-release && echo "$UBUNTU_CODENAME")
if [ -z "$UBUNTU_CODENAME" ]; then
    UBUNTU_CODENAME=$(lsb_release -sc)
fi
echo -e "${YELLOW}Detected OS codename: ${UBUNTU_CODENAME}${NC}"

# Check Secure Boot status
if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
    echo -e "${YELLOW}Secure Boot is enabled.${NC}"
    echo "You may need to disable Secure Boot or enroll a MOK key."
fi

# Clean up any previously failed installations
echo -e "${YELLOW}Cleaning up old packages...${NC}"
apt purge -y bcmwl-kernel-source broadcom-sta-dkms 2>/dev/null || true
apt autoremove -y

# Enable proposed repository temporarily
PROPOSED_FILE="/etc/apt/sources.list.d/${UBUNTU_CODENAME}-proposed-temp.list"
echo -e "${YELLOW}Enabling ${UBUNTU_CODENAME}-proposed repository temporarily...${NC}"
cat > "$PROPOSED_FILE" <<EOF
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-proposed main restricted universe multiverse
EOF

# Update package lists
apt update

# Install DKMS build dependencies to avoid "Error! Bad return status for module build"
echo -e "${YELLOW}Installing build dependencies...${NC}"
apt install -y build-essential dkms linux-headers-$(uname -r)

# Install the fixed driver from proposed
echo -e "${YELLOW}Installing broadcom-sta-dkms from ${UBUNTU_CODENAME}-proposed...${NC}"
apt install -y -t "${UBUNTU_CODENAME}-proposed" broadcom-sta-dkms

# Disable proposed repository
echo -e "${YELLOW}Disabling ${UBUNTU_CODENAME}-proposed repository...${NC}"
rm -f "$PROPOSED_FILE"
apt update

# Blacklist conflicting drivers (only if not already configured)
BLACKLIST_FILE="/etc/modprobe.d/blacklist-broadcom.conf"
if [ ! -f "$BLACKLIST_FILE" ]; then
    echo -e "${YELLOW}Blacklisting conflicting drivers (b43, ssb, bcma)...${NC}"
    cat > "$BLACKLIST_FILE" <<EOF
# Blacklist conflicting Broadcom drivers
blacklist b43
blacklist ssb
blacklist bcma
EOF
else
    echo -e "${YELLOW}Blacklist file already exists, skipping.${NC}"
fi

# Load the wl driver
echo -e "${YELLOW}Loading wl driver...${NC}"
modprobe -r b43 ssb bcma 2>/dev/null || true
modprobe wl || {
    echo -e "${RED}Failed to load wl module. Checking for Secure Boot...${NC}"
    if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
        echo -e "${YELLOW}Secure Boot is enabled and may be blocking the module.${NC}"
        echo -e "Please disable Secure Boot in your Mac's Startup Security Utility."
        echo -e "Hold Cmd+R at boot, go to Utilities > Startup Security Utility,"
        echo -e "and set Secure Boot to 'No Security'."
    fi
    exit 1
}

# Update initramfs
echo -e "${YELLOW}Updating initramfs...${NC}"
update-initramfs -u

# Verify installation
echo -e "${GREEN}Installation complete!${NC}"
if lspci -nn | grep -qi "14e4:43a0"; then
    if lsmod | grep -q wl; then
        echo -e "${GREEN}Driver loaded successfully.${NC}"
        WIFI_IFACE=$(ip link show | grep -Eo 'wl[a-z0-9]+' | head -1)
        if [ -n "$WIFI_IFACE" ]; then
            echo -e "${GREEN}Wi-Fi interface detected: ${WIFI_IFACE}${NC}"
        else
            echo "No wireless interface found yet. Try rebooting."
        fi
    else
        echo -e "${RED}Driver not loaded. Check dmesg for errors.${NC}"
    fi
fi

echo -e "${GREEN}You can now reboot and enjoy built-in Wi-Fi!${NC}"
