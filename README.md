# Mac Mini 2014 WiFi Drivers Installation Script

This repository contains a script to install WiFi drivers for the Mac Mini 2014 when running Linux. The Mac Mini 2014 uses a Broadcom BCM4360 WiFi card, which requires specific drivers to work properly on Linux systems.

## ⚠️ Important Prerequisites

**You MUST have a USB WiFi adapter or Ethernet connection to run this script!**

The Mac Mini 2014's built-in WiFi card will not work until the drivers are installed. Since the script needs to download packages and drivers from the internet, you need an alternative internet connection:
- USB WiFi adapter (recommended)
- Ethernet connection
- USB tethering from a phone

## System Requirements

- Mac Mini 2014 (Late 2014)
- Linux operating system (Ubuntu, Debian, or derivatives)
- Active internet connection (via USB WiFi or Ethernet)
- Root/sudo privileges
- At least 500MB of free disk space

## What This Script Does

The `install-broadcom-wifi.sh` script will:
1. Install necessary build tools and kernel headers
2. Download the appropriate Broadcom wireless drivers
3. Compile and install the drivers for your system
4. Configure the system to load the drivers automatically
5. Set up the WiFi interface

The script specifically targets the **Broadcom BCM4360** chipset used in the Mac Mini 2014.

## Installation Instructions

### Step 1: Download the Script

Clone this repository or download the script directly:

```bash
# Clone the repository
git clone https://github.com/Mrjam007/Mac2014WIFIdrivers-mini.git
cd Mac2014WIFIdrivers-mini

# OR download directly (if you have wget/curl)
wget https://raw.githubusercontent.com/Mrjam007/Mac2014WIFIdrivers-mini/main/install-broadcom-wifi.sh
```

### Step 2: Make the Script Executable

```bash
chmod +x install-broadcom-wifi.sh
```

### Step 3: Run the Script

Run the script with sudo privileges:

```bash
sudo ./install-broadcom-wifi.sh
```

The script will:
- Check your system configuration
- Install required dependencies
- Download and install the Broadcom drivers
- Configure the WiFi interface

### Step 4: Reboot Your System

After the script completes successfully, reboot your Mac Mini:

```bash
sudo reboot
```

### Step 5: Verify Installation

After rebooting, verify that your WiFi is working:

```bash
# Check if the WiFi interface is detected
ip link show

# Check for wireless networks
nmcli device wifi list

# Or use
iwconfig
```

## Troubleshooting

### WiFi Interface Not Detected

If the WiFi interface is not detected after installation:

1. Check if the driver module is loaded:
```bash
lsmod | grep wl
```

2. Check kernel messages for errors:
```bash
dmesg | grep -i broadcom
```

3. Try manually loading the driver:
```bash
sudo modprobe wl
```

### Script Fails During Execution

- **Error: Unable to locate package**: Make sure your USB WiFi/Ethernet is working and you can access the internet
  ```bash
  ping -c 4 google.com
  sudo apt update
  ```

- **Error: No kernel headers found**: Update your system first
  ```bash
  sudo apt update && sudo apt upgrade
  sudo apt install linux-headers-$(uname -r)
  ```

- **Error: Compilation failed**: You may need to install additional build tools
  ```bash
  sudo apt install build-essential dkms
  ```

### WiFi Works But Connection is Unstable

1. Check signal strength:
```bash
iwconfig
```

2. Try updating the firmware:
```bash
sudo apt install firmware-b43-installer
```

3. Check for interference - Mac Mini WiFi can be sensitive to USB 3.0 devices

### Reverting Changes

If you need to remove the drivers:

```bash
sudo apt remove broadcom-sta-dkms
sudo apt remove bcmwl-kernel-source
```

Then reboot your system.

## Supported Distributions

This script has been tested on:
- Ubuntu 20.04, 22.04, 24.04
- Linux Mint 20, 21, 22
- Debian 11, 12
- Pop!_OS 22.04

Other Debian-based distributions should work but may require modifications.

## Known Issues

- The Broadcom BCM4360 driver may not support all WiFi features (e.g., 5GHz on some kernels)
- USB 3.0 devices may interfere with WiFi signal quality (known hardware issue with Mac Mini 2014)
- Some distributions require firmware-b43-installer in addition to the main drivers

## Security Considerations

- Always review scripts before running them with sudo
- This script installs proprietary Broadcom drivers
- Keep your system updated for security patches
- Make sure to download the script from this official repository

## Additional Resources

- [Mac Mini 2014 Specifications](https://support.apple.com/kb/SP710)
- [Broadcom Linux Driver Support](https://www.broadcom.com/support/download-search)
- [Ubuntu WiFi Troubleshooting](https://help.ubuntu.com/community/WifiDocs/Driver/bcm43xx)

## Contributing

If you encounter issues or have improvements:
1. Open an issue describing the problem
2. Include your Linux distribution and version
3. Provide relevant error messages or logs

## License

This script is provided as-is for educational and convenience purposes. The Broadcom drivers are proprietary and subject to their own licenses.

## Credits

Created for the Mac Mini 2014 Linux community. Special thanks to all contributors and testers.

---

**Note**: This script is specifically for the Mac Mini 2014 model. Other Mac models may use different WiFi hardware and require different drivers.