# 🚀 Tailscale Exit Node Auto-Configuration for Linode

[![Tailscale](https://img.shields.io/badge/Tailscale-Compatible-blue)](https://tailscale.com)
[![Linode](https://img.shields.io/badge/Linode-StackScript-green)](https://www.linode.com/stackscripts/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04-orange)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-10%20%7C%2011-red)](https://www.debian.org/)

> 🔐 Transform your Linode instance into a secure Tailscale Exit Node with just one click!

This StackScript automatically configures a Linode instance as a Tailscale Exit Node (Gateway), allowing other devices in your Tailscale network to route their internet traffic through this server.

## 📋 Table of Contents

- [What is a Tailscale Exit Node?](#-what-is-a-tailscale-exit-node)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Supported Distributions](#-supported-distributions)
- [Configuration Options](#%EF%B8%8F-configuration-options)
- [Post-Installation Steps](#-post-installation-steps)
- [Usage Examples](#-usage-examples)
- [Security Considerations](#-security-considerations)
- [Monitoring & Troubleshooting](#-monitoring--troubleshooting)
- [Contributing](#-contributing)

## 🌐 What is a Tailscale Exit Node?

An Exit Node acts as a VPN gateway, enabling secure internet access for all devices in your Tailscale network through a single exit point. 

### 🎯 Use Cases

| Use Case | Description |
|----------|-------------|
| 🌍 **Geo-restriction Bypass** | Access content from the Exit Node's location |
| 🔒 **Public WiFi Security** | Secure your traffic on untrusted networks |
| 🏢 **Corporate Access** | Maintain consistent IP for business services |
| 🏠 **Home Network Access** | Access your home network remotely |

## ✨ Features

- ⚡ **Automatic Installation** - Complete Tailscale setup in minutes
- 🔄 **Dual Stack Support** - IPv4 and IPv6 forwarding enabled
- 🛡️ **Firewall Configuration** - Pre-configured firewalld rules
- 🌊 **NAT/Masquerade** - Automatic traffic routing setup
- 🔑 **SSH Integration** - Optional SSH access via Tailscale
- 📝 **Complete Logging** - All operations logged to `/var/log/stackscript.log`
- 🚀 **Zero Touch Deployment** - Fully automated configuration

## 📚 Prerequisites

### 1. Tailscale Account
Create a free account at [https://tailscale.com](https://tailscale.com)

### 2. Authentication Key
Generate an auth key for automatic device registration:

1. Navigate to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click **"Generate auth key"**
3. ✅ Enable **"Reusable"** for multiple deployments
4. 📋 Copy the key (format: `tskey-auth-XXXXX`)

## 🚀 Quick Start

### Step 1: Deploy the StackScript

```bash
# Option 1: Use from Linode Marketplace
1. Go to Linode Dashboard
2. Create > Linode
3. Choose "StackScripts" tab
4. Search for "Tailscale Exit Node"
5. Fill in the configuration options
6. Deploy!

# Option 2: Create your own StackScript
1. Copy the script from this repository
2. Create new StackScript in Linode Dashboard
3. Deploy with your configuration

💻 Supported Distributions
Distribution	Version	Status
Ubuntu	20.04 LTS	✅ Tested
Ubuntu	22.04 LTS	✅ Tested
Debian	10 (Buster)	✅ Tested
Debian	11 (Bullseye)	✅ Tested

⚙️ Configuration Options
Parameter	Type	Required	Default	Description
tailscale_authkey	String	✅ Yes	-	Your Tailscale authentication key
hostname	String	❌ No	Tailscale-Gateway	Custom hostname for the Exit Node
enable_ssh	Boolean	❌ No	yes	Enable SSH access via Tailscale network
Example Configuration
yaml


tailscale_authkey: "tskey-auth-kF7NS2CXXX-XXXXXXXXXXXXXXXXX"
hostname: "my-exit-node"
enable_ssh: "yes"
📋 Post-Installation Steps
1. ✅ Approve the Exit Node
The Exit Node needs approval in your Tailscale admin console:

Go to Machines
Find your new Exit Node
Click the ⋮ menu
Select "Edit route settings"
Enable "Use as exit node"
2. 🔍 Verify Installation
SSH into your Linode and check the status:

bash


# Check Tailscale status
tailscale status

# Verify exit node advertisement
tailscale debug exit-node-status

# Check logs
tail -f /var/log/stackscript.log
💡 Usage Examples
Basic Usage
bash


# Connect using hostname
tailscale up --exit-node=Tailscale-Gateway

# Disconnect from exit node
tailscale up --exit-node=
Advanced Configuration
bash


# Use exit node with specific options
tailscale up --exit-node=Tailscale-Gateway --exit-node-allow-lan-access

# Route only specific traffic through exit node
tailscale up --exit-node=Tailscale-Gateway --accept-routes
🔒 Security Considerations
⚠️ Important Security Notes
Trust Requirement - This server will handle all routed internet traffic
Access Control - Use Tailscale ACLs to restrict access
Updates - Keep the system updated with security patches
Monitoring - Regularly check logs for suspicious activity
🛡️ Recommended Security Practices
bash


# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure Tailscale ACLs (in admin console)
{
  "acls": [
    {
      "action": "accept",
      "users": ["group:admins"],
      "ports": ["*:*"]
    }
  ]
}
🔍 Monitoring & Troubleshooting
📊 Monitoring Commands
bash


# Check Tailscale status
tailscale status

# View active connections
tailscale netcheck

# Check exit node status
tailscale debug exit-node-status

# View logs
journalctl -u tailscaled -f
tail -f /var/log/stackscript.log
🔧 Common Issues
Issue	Solution
Exit node not appearing	Restart Tailscale: sudo systemctl restart tailscaled
Connection refused	Check firewall: sudo firewall-cmd --list-all
Slow performance	Check bandwidth: tailscale netcheck
Authentication failed	Regenerate auth key with "Reusable" option
📈 Performance Tuning
bash


# Increase network buffer sizes
echo 'net.core.rmem_max = 134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Monitor network performance
iftop -i tailscale0
🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

Fork the repository
Create your feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Tailscale for the amazing VPN solution
Linode for the StackScript platform
Community contributors and testers
