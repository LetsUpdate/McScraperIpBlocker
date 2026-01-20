# KittyScan IP Blocker

Automated IP blocking solution for Ubuntu/Debian VPS systems to protect Minecraft servers from scanner IPs using UFW firewall.

## 📋 Overview

This project provides an automated solution to download and block scanner IPs from the [KittyScanBlocklist repository](https://github.com/LillySchramm/KittyScanBlocklist). The blocklist contains IP addresses detected scanning for Minecraft servers and is updated every 24 hours by KittyScan honeypots.

**Why this matters:** Scanner IPs can lead to increased server load, potential security vulnerabilities, and unwanted traffic. This tool helps protect your Minecraft server by automatically blocking known scanner IPs.

## ✨ Features

- 🔄 **Automatic Updates**: Downloads the latest IP blocklist daily
- 🚀 **Systemd Integration**: Runs automatically at system boot
- 📝 **Comprehensive Logging**: All activities logged to `/var/log/kittyscan-blocker.log`
- 🛡️ **UFW Firewall**: Uses UFW for simple, persistent firewall management
- 🏷️ **Tagged Rules**: All rules tagged with "KITTYSCAN" for easy identification and removal
- ⚡ **Error Handling**: Graceful handling of network failures and UFW issues
- 🧹 **Auto Cleanup**: Automatically removes old rules before adding new ones
- ⏰ **Flexible Scheduling**: Supports both systemd and cron-based scheduling

## 📦 Prerequisites

Before installing, ensure you have:

- **Ubuntu/Debian-based system** (Ubuntu 18.04+, Debian 9+, or similar)
- **UFW (Uncomplicated Firewall)** installed and enabled
- **Root/sudo access** for installation
- **curl** for downloading blocklists
- **Active internet connection**

### Why UFW?

This project uses UFW because:
- Standard firewall frontend on Ubuntu/Debian systems
- Simple, user-friendly syntax compared to raw iptables
- Automatically persists rules across reboots
- Easier to manage and troubleshoot for VPS administrators
- Widely documented and supported in the Ubuntu ecosystem

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/LetsUpdate/McScraperIpBlocker.git
cd McScraperIpBlocker

# Make the installation script executable
chmod +x install.sh

# Run the installation (requires root)
sudo ./install.sh
```

The installation script will:
1. Check system requirements
2. Verify UFW is installed and enabled
3. Install the blocking script and systemd service
4. Optionally configure cron jobs
5. Run an initial blocklist update

## 🔧 Manual Installation

If you prefer to install manually:

### Step 1: Install UFW (if not already installed)

```bash
sudo apt-get update
sudo apt-get install ufw curl
```

### Step 2: Configure UFW

**⚠️ CRITICAL: Allow SSH before enabling UFW to avoid lockout!**

```bash
# Allow SSH access
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Enable UFW
sudo ufw enable

# Verify status
sudo ufw status
```

### Step 3: Install the blocking script

```bash
# Copy the main script
sudo cp block-scanners.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/block-scanners.sh

# Create log file
sudo touch /var/log/kittyscan-blocker.log
sudo chmod 644 /var/log/kittyscan-blocker.log
```

### Step 4: Install systemd service

```bash
# Copy service file
sudo cp kittyscan-blocker.service /etc/systemd/system/

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable kittyscan-blocker.service
```

### Step 5: Configure cron (optional)

```bash
# Edit root crontab
sudo crontab -e

# Add these lines:
@reboot /usr/local/bin/block-scanners.sh
0 3 * * * /usr/local/bin/block-scanners.sh
```

### Step 6: Run initial update

```bash
sudo /usr/local/bin/block-scanners.sh
```

## ⚙️ Configuration Options

The KittyScanBlocklist repository provides different blocklist files:

- **`ips.txt`**: All detected scanner IPs (largest list, most comprehensive)
- **`ips-16.txt`**: IPs detected in the last 16 days (balanced option)
- **`ips-24.txt`**: IPs detected in the last 24 hours (default, most recent and actively scanning)

To change which blocklist to use, edit `/usr/local/bin/block-scanners.sh` and modify the `BLOCKLIST_URL` variable:

```bash
# For 24-hour list (default - recommended for active protection)
BLOCKLIST_URL="https://raw.githubusercontent.com/LillySchramm/KittyScanBlocklist/main/ips-24.txt"

# For 16-day list (more comprehensive)
BLOCKLIST_URL="https://raw.githubusercontent.com/LillySchramm/KittyScanBlocklist/main/ips-16.txt"

# For complete list (most comprehensive, larger rule set)
BLOCKLIST_URL="https://raw.githubusercontent.com/LillySchramm/KittyScanBlocklist/main/ips.txt"
```

**Recommendation**: Use `ips-24.txt` (default) for the most recent and actively scanning IPs, or `ips-16.txt` for a balance between comprehensive blocking and reduced rule count.

## 📖 Usage

### Verify Installation

Check that blocking rules are active:

```bash
# View all KITTYSCAN rules
sudo ufw status numbered | grep KITTYSCAN

# Count active rules
sudo ufw status numbered | grep -c KITTYSCAN
```

### View Logs

Monitor the activity log:

```bash
# View recent log entries
sudo tail -f /var/log/kittyscan-blocker.log

# View full log
sudo cat /var/log/kittyscan-blocker.log

# Search for errors
sudo grep ERROR /var/log/kittyscan-blocker.log
```

### Manual Updates

Trigger a manual blocklist update:

```bash
sudo /usr/local/bin/block-scanners.sh
```

### Check Service Status

```bash
# View systemd service status
sudo systemctl status kittyscan-blocker

# View service logs
sudo journalctl -u kittyscan-blocker -f
```

### View UFW Status

```bash
# Full numbered status
sudo ufw status numbered

# Verbose status
sudo ufw status verbose
```

## 📅 Scheduling Options

This project supports two scheduling methods:

### Systemd (Recommended)

The systemd service runs the blocker at system boot automatically. This is enabled during installation.

**Benefits:**
- Automatic execution at boot
- Integrated with system logging
- Easy to manage with `systemctl`

### Cron

Cron provides scheduled updates (e.g., daily at 3 AM).

**Benefits:**
- Regular scheduled updates
- Flexible timing options
- Independent of systemd

**Both methods can be used together** for redundancy.

## 🔍 Troubleshooting

### UFW Not Installed

**Error**: `UFW is not installed`

**Solution**:
```bash
sudo apt-get update
sudo apt-get install ufw
```

### UFW Not Enabled

**Error**: `UFW is not currently active`

**Solution**:
```bash
# IMPORTANT: Allow SSH first!
sudo ufw allow ssh
sudo ufw enable
```

### Network Download Failures

**Error**: `Failed to download blocklist`

**Solutions**:
- Check internet connection: `ping -c 3 github.com`
- Verify curl is installed: `curl --version`
- Check if GitHub is accessible: `curl -I https://github.com`
- Review firewall rules that might block outbound connections

### Permission Denied

**Error**: `Permission denied`

**Solution**: Ensure you're running with sudo/root:
```bash
sudo /usr/local/bin/block-scanners.sh
```

### Too Many UFW Rules

If you have thousands of rules and UFW becomes slow:

1. Consider using a shorter blocklist (e.g., `ips-24.txt` instead of `ips.txt`)
2. Monitor performance: `sudo ufw status | wc -l`
3. Use `iptables` directly for very large rule sets (advanced)

### Rules Not Persisting

UFW rules should persist automatically. If they don't:

```bash
# Reload UFW
sudo ufw reload

# Check UFW is enabled
sudo ufw status
```

### Script Not Running at Boot

```bash
# Check systemd service
sudo systemctl status kittyscan-blocker
sudo systemctl enable kittyscan-blocker

# Check service logs
sudo journalctl -u kittyscan-blocker
```

## 🔒 Important Security Notes

### ⚠️ Critical Warnings

1. **SSH Access**: Before enabling UFW, ALWAYS allow SSH to avoid being locked out:
   ```bash
   sudo ufw allow ssh
   sudo ufw allow 22/tcp
   ```

2. **Scanner IPs ≠ Malicious IPs**: The blocklist contains scanner IPs, not necessarily malicious actors. Scanners are often legitimate services checking server availability.

3. **Review Before Production**: Always review the blocklist and test on a non-production system first.

4. **False Positives**: Some legitimate services might be blocked if they scan servers. Monitor your logs.

5. **Backup Access**: Ensure you have alternative access methods (console access, recovery mode) before implementing on production systems.

### Best Practices

- Regularly review `/var/log/kittyscan-blocker.log`
- Monitor for unexpected connection blocks
- Keep UFW rules organized and documented
- Test blocklist updates on staging systems first
- Maintain backup access to your server

## 🗑️ Uninstallation

To completely remove KittyScan IP Blocker:

### Step 1: Remove all KITTYSCAN rules

```bash
# This will remove all blocking rules
sudo /usr/local/bin/block-scanners.sh
# Then manually delete all KITTYSCAN rules or use:
sudo ufw status numbered | grep KITTYSCAN | grep -oP '^\[\s*\K[0-9]+' | sort -rn | while read n; do sudo ufw --force delete $n; done
```

### Step 2: Stop and disable the service

```bash
sudo systemctl stop kittyscan-blocker
sudo systemctl disable kittyscan-blocker
```

### Step 3: Remove installed files

```bash
sudo rm /usr/local/bin/block-scanners.sh
sudo rm /etc/systemd/system/kittyscan-blocker.service
sudo rm /var/log/kittyscan-blocker.log
sudo systemctl daemon-reload
```

### Step 4: Remove cron entries

```bash
sudo crontab -e
# Remove lines containing 'block-scanners.sh'
```

## 🙏 Credits

- **Blocklist Source**: [KittyScanBlocklist](https://github.com/LillySchramm/KittyScanBlocklist) by [LillySchramm](https://github.com/LillySchramm)
- **KittyScan Project**: Honeypot system detecting Minecraft server scanners
- Blocklist updated every 24 hours with IPs from KittyScan honeypots

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Areas for Contribution

- Support for additional firewall systems (iptables, firewalld)
- IPv6 support enhancements
- Performance optimizations for large blocklists
- Additional logging and monitoring features
- Integration with other security tools

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/LetsUpdate/McScraperIpBlocker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/LetsUpdate/McScraperIpBlocker/discussions)

## 🔄 Updates

Check the [releases page](https://github.com/LetsUpdate/McScraperIpBlocker/releases) for the latest updates and changelogs.

---

**Made with ❤️ for the Minecraft server community**
