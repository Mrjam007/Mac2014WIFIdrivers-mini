# Mac Mini 2014 WiFi Drivers Installation Script

This repository contains a script to install WiFi drivers for the **Mac Mini 7,1 (Late 2014)** when running **Ubuntu 24.04 (Noble)**. The Mac Mini 2014 uses a **Broadcom BCM4360** WiFi card, which requires proprietary drivers to work properly on Linux systems.

## ⚠️ Important Prerequisites

**You MUST have a USB WiFi adapter or Ethernet connection to run this script!**

The Mac Mini 2014's built-in WiFi card will not work until the drivers are installed. Since the script needs to download packages and drivers from the internet, you need an alternative internet connection:
- USB WiFi adapter (recommended)
- Ethernet connection
- USB tethering from a phone

## System Requirements

- **Mac Mini 7,1** (Late 2014) with BCM4360 WiFi card
- **Ubuntu 24.04 (Noble)** or derivatives (the script will warn if running on other versions)
- **Active internet connection** (via USB WiFi or Ethernet)
- **Root/sudo privileges**
- At least 500MB of free disk space
- **Secure Boot disabled** (see below for details)

## What This Script Does

The `install-broadcom-wifi.sh` script performs the following steps:

1. **Checks prerequisites**: Verifies root privileges and internet connectivity
2. **Detects Ubuntu version**: Ensures you're running Ubuntu 24.04 (Noble)
3. **Cleans up old installations**: Removes any previously failed driver installations
4. **Enables noble-proposed repository**: Temporarily enables this repository to access the fixed driver
5. **Installs broadcom-sta-dkms**: Downloads and installs the proprietary Broadcom driver package
6. **Disables noble-proposed**: Removes the repository after installation
7. **Blacklists conflicting drivers**: Prevents b43, ssb, and bcma drivers from interfering
8. **Loads the wl driver**: Activates the Broadcom wireless driver
9. **Updates initramfs**: Ensures the driver loads on next boot
10. **Verifies installation**: Checks if the WiFi interface (wlp2s0) is available

After installation, your WiFi interface will appear as **wlp2s0**.

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

The script will automatically:
- Check for root privileges and internet connectivity
- Clean up any old driver installations
- Temporarily enable the noble-proposed repository
- Install the broadcom-sta-dkms package with the fixed driver
- Blacklist conflicting drivers (b43, ssb, bcma)
- Load the wl (Broadcom wireless) driver
- Update the initramfs for next boot
- Verify the installation

**Expected output**: You should see green success messages and the script will indicate if the driver loaded successfully.

### Step 4: Reboot Your System

After the script completes successfully, reboot your Mac Mini:

```bash
sudo reboot
```

### Step 5: Verify Installation

After rebooting, verify that your WiFi is working:

```bash
# Check if the WiFi interface (wlp2s0) is detected
ip link show

# Look for the wlp2s0 interface
ip link show wlp2s0

# Check for wireless networks
nmcli device wifi list

# Or use
iwconfig
```

Your built-in WiFi should now appear as **wlp2s0** and you can connect to wireless networks!

## Troubleshooting

### Secure Boot Issues

**Most Common Issue**: If the script fails to load the wl module with a message about "Lockdown" in dmesg, you need to disable Secure Boot.

The wl driver is a proprietary module that cannot be loaded when Secure Boot is enabled. To disable Secure Boot on Mac Mini:

1. **Restart** your Mac Mini
2. Hold **Cmd+R** during boot to enter Recovery Mode
3. Go to **Utilities → Startup Security Utility**
4. Authenticate with your admin password
5. Set **Secure Boot** to **"No Security"**
6. Restart and run the script again

### Script Reports "No internet connection"

The script checks connectivity by pinging archive.ubuntu.com. If this fails:

```bash
# Test your connection manually
ping -c 4 8.8.8.8

# If that works but archive.ubuntu.com doesn't, try:
ping -c 4 google.com

# Check your DNS settings
cat /etc/resolv.conf
```

Make sure your USB WiFi adapter or Ethernet cable is properly connected.

### WiFi Interface Not Detected After Reboot

If the wlp2s0 interface doesn't appear after rebooting:

1. Check if the driver module is loaded:
```bash
lsmod | grep wl
```

2. Check kernel messages for errors:
```bash
dmesg | grep -i broadcom
dmesg | grep -i wl
```

3. Verify the BCM4360 hardware is detected:
```bash
lspci -nn | grep BCM4360
```

4. Try manually loading the driver:
```bash
sudo modprobe wl
```

5. Check if conflicting drivers are loaded:
```bash
lsmod | grep -E "b43|ssb|bcma"
```

If conflicting drivers are loaded, unload them:
```bash
sudo modprobe -r b43 ssb bcma
sudo modprobe wl
```

### Script Fails on Non-Ubuntu 24.04 Systems

The script is specifically designed for Ubuntu 24.04 (Noble) and uses the noble-proposed repository. If you're running a different version:

- The script will show a warning but continue
- You may need to modify the repository lines in the script
- Consider upgrading to Ubuntu 24.04 for best compatibility

### WiFi Works But Connection is Unstable

1. Check signal strength:
```bash
iwconfig wlp2s0
```

2. Check for interference - Mac Mini WiFi can be sensitive to USB 3.0 devices nearby

3. Try disabling power management for the WiFi:
```bash
sudo iwconfig wlp2s0 power off
```

### Reverting Changes

If you need to remove the drivers:

```bash
sudo apt-get purge broadcom-sta-dkms
sudo apt-get autoremove
sudo rm -f /etc/modprobe.d/blacklist-broadcom.conf
sudo update-initramfs -u
sudo reboot
```

## Supported Distributions

This script is specifically designed for:
- **Ubuntu 24.04 (Noble)** - Primary target, fully tested
- Ubuntu derivatives based on 24.04 (Kubuntu, Xubuntu, Ubuntu MATE, etc.)

**Note**: The script uses the `noble-proposed` repository, which is specific to Ubuntu 24.04. If you're running a different Ubuntu version or Debian-based distribution, you may need to:
- Modify the repository references in the script
- Use alternative installation methods
- Consider upgrading to Ubuntu 24.04

## Known Issues

- **Secure Boot**: The proprietary wl driver cannot be loaded with Secure Boot enabled. You must disable Secure Boot in the Mac's Startup Security Utility.
- **USB 3.0 interference**: USB 3.0 devices plugged into the Mac Mini can interfere with WiFi signal quality (known hardware issue). Try using USB 2.0 ports or devices if you experience connectivity issues.
- **noble-proposed requirement**: The script requires the noble-proposed repository, which is specific to Ubuntu 24.04. Other distributions need script modifications.
- **Interface naming**: The WiFi interface will always be named `wlp2s0` on Mac Mini 7,1

## Security Considerations

- **Review before running**: Always review scripts before running them with sudo privileges
- **Proprietary drivers**: This script installs proprietary Broadcom drivers (wl module)
- **Secure Boot**: You must disable Secure Boot for the driver to work, which reduces boot security
- **Repository security**: The script temporarily enables noble-proposed, which contains pre-release packages
- **System updates**: Keep your system updated for security patches
- **Trusted source**: Make sure to download the script from this official repository only

## How the Script Works (Technical Details)

For those interested in the technical details:

1. **Repository Management**: The script temporarily adds `/etc/apt/sources.list.d/noble-proposed.list` to access pre-release packages with fixes for the BCM4360 driver.

2. **Package Installation**: Uses `apt-get install -y -t noble-proposed broadcom-sta-dkms` to install the specific fixed version.

3. **Driver Conflicts**: Creates `/etc/modprobe.d/blacklist-broadcom.conf` to prevent the open-source b43, ssb, and bcma drivers from loading, as they conflict with the proprietary wl driver.

4. **Module Loading**: Uses `modprobe wl` to load the Broadcom wireless driver, and `modprobe -r` to remove conflicting modules.

5. **Boot Configuration**: Runs `update-initramfs -u` to ensure the driver and blacklist configuration are applied at boot time.

6. **Verification**: Checks for the BCM4360 hardware using `lspci` and verifies the wl module is loaded using `lsmod`.

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