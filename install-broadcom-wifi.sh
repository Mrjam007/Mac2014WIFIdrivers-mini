#!/bin/bash
# Broadcom Wi-Fi Driver Installer for Mac Mini 7,1 (BCM4360)
# For Ubuntu 24.04 (Noble) and derivatives

set -e  # Exit on error

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

# Check internet connectivity
echo -e "${YELLOW}Checking internet connection...${NC}"
if ! ping -c 1 archive.ubuntu.com &> /dev/null; then
    echo -e "${RED}No internet connection. Please connect via USB adapter or Ethernet and try again.${NC}"
    exit 1
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -sc)
if [ "$UBUNTU_VERSION" != "noble" ]; then
    echo -e "${RED}This script is designed for Ubuntu 24.04 (Noble). Detected: $UBUNTU_VERSION${NC}"
    echo -e "${YELLOW}Continuing anyway, but compatibility is not guaranteed.${NC}"
fi

# Clean up any previously failed installations
echo -e "${YELLOW}Cleaning up old packages...${NC}"
apt-get purge -y bcmwl-kernel-source broadcom-sta-dkms 2>/dev/null || true
apt-get autoremove -y

# Enable noble-proposed repository
echo -e "${YELLOW}Enabling noble-proposed repository temporarily...${NC}"
cat > /etc/apt/sources.list.d/noble-proposed.list <<EOF
deb http://archive.ubuntu.com/ubuntu noble-proposed main restricted universe multiverse
EOF

# Update package lists
apt-get update

# Install the fixed driver from proposed
echo -e "${YELLOW}Installing broadcom-sta-dkms from noble-proposed...${NC}"
apt-get install -y -t noble-proposed broadcom-sta-dkms

# Disable proposed repository
echo -e "${YELLOW}Disabling noble-proposed repository...${NC}"
rm -f /etc/apt/sources.list.d/noble-proposed.list
apt-get update

# Blacklist conflicting drivers
echo -e "${YELLOW}Blacklisting conflicting drivers (b43, ssb, bcma)...${NC}"
cat > /etc/modprobe.d/blacklist-broadcom.conf <<EOF
# Blacklist conflicting Broadcom drivers
blacklist b43
blacklist ssb
blacklist bcma
EOF

# Load the wl driver
echo -e "${YELLOW}Loading wl driver...${NC}"
modprobe -r b43 ssb bcma 2>/dev/null || true
modprobe wl || {
    echo -e "${RED}Failed to load wl module. Checking for Secure Boot...${NC}"
    if dmesg | grep -q "Lockdown"; then
        echo -e "${YELLOW}Secure Boot may be blocking the module.${NC}"
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
if lspci -nn | grep -qi "BCM4360.*Network controller"; then
    if lsmod | grep -q wl; then
        echo -e "${GREEN}Driver loaded successfully. Your internal Wi-Fi interface should appear as wlp2s0.${NC}"
        ip link show | grep -o 'wl[^:]*' || echo "No wireless interface found yet. Try rebooting."
    else
        echo -e "${RED}Driver not loaded. Check dmesg for errors.${NC}"
    fi
else
    echo -e "${RED}BCM4360 not detected. This script may not be needed for your hardware.${NC}"
fi

echo -e "${GREEN}You can now reboot and enjoy built-in Wi-Fi!${NC}"
