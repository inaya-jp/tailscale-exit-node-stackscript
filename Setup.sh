#!/bin/bash
# <UDF name="tailscale_authkey" label="Tailscale Auth Key" example="tskey-auth-xxxx" />
# <UDF name="hostname" label="Hostname for Exit Node" default="Tailscale-Gateway" />
# <UDF name="enable_ssh" label="Enable SSH access via Tailscale" oneOf="yes,no" default="yes" />
# <UDF name="enable_auto_update" label="Enable Tailscale auto-updates" oneOf="yes,no" default="yes" />

# Tailscale Exit Node StackScript for Linode
# This script automatically configures a Linode instance as a Tailscale Exit Node
# 
# Prerequisites:
# 1. Generate an auth key at https://login.tailscale.com/admin/settings/keys
# 2. Use a reusable key if you plan to redeploy this script multiple times

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display step
print_step() {
    echo -e "\n${BLUE}[Step $1]${NC} $2"
    echo "================================================"
}

# Function to display success message
print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Function to display warning message
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display error message
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Log all output
exec > >(tee -a /var/log/stackscript.log)
exec 2>&1

# Script start
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Tailscale Exit Node Setup Script${NC}"
echo -e "${BLUE}Started at: $(date)${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if auth key is provided
if [ -z "$TAILSCALE_AUTHKEY" ]; then
    print_error "Tailscale auth key not provided. Exiting..."
    exit 1
fi

# 1. Update system
print_step "1/9" "Updating system packages"
apt-get update
apt-get upgrade -y
print_success "System updated"

# 2. Set hostname
print_step "2/9" "Setting hostname"
echo "Setting hostname to '$HOSTNAME'..."
hostnamectl set-hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname
print_success "Hostname set to: $(hostname)"

# 3. Install Tailscale
print_step "3/9" "Installing Tailscale"
echo "Downloading and executing official Tailscale installation script..."
curl -fsSL https://tailscale.com/install.sh | sh
if [ $? -eq 0 ]; then
    print_success "Tailscale successfully installed"
else
    print_error "Failed to install Tailscale"
    exit 1
fi

# 4. Configure Tailscale auto-updates
print_step "4/9" "Configuring Tailscale auto-updates"
if [ "$ENABLE_AUTO_UPDATE" = "yes" ]; then
    echo "Enabling Tailscale auto-updates..."
    
    # Enable automatic updates
    tailscale set --auto-update
    
    # Create systemd timer for regular update checks
    cat > /etc/systemd/system/tailscale-update.service << EOF
[Unit]
Description=Tailscale Update Check
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/tailscale update --yes
User=root
EOF

    cat > /etc/systemd/system/tailscale-update.timer << EOF
[Unit]
Description=Check for Tailscale updates daily
Requires=tailscale-update.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Enable and start the timer
    systemctl daemon-reload
    systemctl enable tailscale-update.timer
    systemctl start tailscale-update.timer
    
    print_success "Tailscale auto-updates enabled (daily check)"
    
    # Also set up unattended-upgrades for system security updates
    echo "Installing unattended-upgrades for system security updates..."
    apt-get install -y unattended-upgrades apt-listchanges
    
    # Configure unattended-upgrades
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
    "Tailscale Inc.:stable";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

    # Enable automatic updates
    echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::AutocleanInterval "7";' >> /etc/apt/apt.conf.d/20auto-upgrades
    
    systemctl enable unattended-upgrades
    systemctl start unattended-upgrades
    
    print_success "System auto-updates also configured"
else
    print_warning "Tailscale auto-updates disabled"
fi

# 5. Enable IP forwarding
print_step "5/9" "Enabling IP forwarding"
echo "Enabling IPv4 and IPv6 packet forwarding..."

# Enable IPv4 forwarding
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf
print_success "IP forwarding enabled"

# 6. Install and configure firewalld
print_step "6/9" "Installing and configuring firewalld"

# Install firewalld
apt-get install -y firewalld
systemctl start firewalld
systemctl enable firewalld
print_success "firewalld installed and started"

# 7. Configure firewalld
print_step "7/9" "Configuring firewall rules"

# Get default internet connection interface
DEFAULT_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
print_success "Detected interface: $DEFAULT_IF"

# Configure firewall zones
firewall-cmd --zone=public --add-interface=$DEFAULT_IF --permanent
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --zone=trusted --add-interface=tailscale0 --permanent
firewall-cmd --zone=public --add-forward --permanent
firewall-cmd --reload
print_success "Firewall rules configured"

# 8. Configure Tailscale with auth key
print_step "8/9" "Configuring Tailscale as Exit Node"
echo "Starting Tailscale with provided auth key..."

# Start Tailscale with auth key and exit node advertisement
tailscale up --authkey="$TAILSCALE_AUTHKEY" --advertise-exit-node --accept-routes --hostname="$HOSTNAME"

if [ $? -eq 0 ]; then
    print_success "Tailscale started successfully as Exit Node"
else
    print_error "Failed to start Tailscale"
    exit 1
fi

# 9. Optional: Configure SSH access
print_step "9/9" "Configuring SSH access"
if [ "$ENABLE_SSH" = "yes" ]; then
    echo "Configuring SSH to accept connections from Tailscale..."
    
    # Backup original sshd_config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Allow SSH from Tailscale network
    echo "" >> /etc/ssh/sshd_config
    echo "# Allow SSH from Tailscale network" >> /etc/ssh/sshd_config
    echo "Match Address 100.64.0.0/10" >> /etc/ssh/sshd_config
    echo "    PasswordAuthentication yes" >> /etc/ssh/sshd_config
    
    systemctl restart sshd
    print_success "SSH configured for Tailscale access"
else
    print_warning "SSH access via Tailscale not configured"
fi

# Final status check
echo ""
print_step "Final" "Checking Tailscale status and update configuration"
sleep 5
tailscale status

# Check auto-update status
if [ "$ENABLE_AUTO_UPDATE" = "yes" ]; then
    echo ""
    echo "Auto-update timer status:"
    systemctl status tailscale-update.timer --no-pager
    echo ""
    echo "Next scheduled update check:"
    systemctl list-timers tailscale-update.timer --no-pager
fi

# Completion message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
print_success "This Linode instance is now configured as a Tailscale Exit Node"

if [ "$ENABLE_AUTO_UPDATE" = "yes" ]; then
    echo ""
    print_success "Tailscale auto-updates are enabled and will check daily"
    echo "Manual update command: tailscale update"
    echo "Check update status: systemctl status tailscale-update.timer"
fi

echo ""
echo "Important next steps:"
echo "1. Approve this Exit Node in the Tailscale admin console:"
echo "   https://login.tailscale.com/admin/machines"
echo ""
echo "2. To use this Exit Node from other devices, run:"
echo "   tailscale up --exit-node=$HOSTNAME"
echo "   or"
echo "   tailscale up --exit-node=$(tailscale ip -4)"
echo ""
echo "3. To check Exit Node status:"
echo "   tailscale status"
echo "   tailscale exit-node list"
echo ""
echo "4. Update management:"
echo "   - Manual update: tailscale update"
echo "   - Check for updates: tailscale update --check"
echo "   - View update logs: journalctl -u tailscale-update.service"
echo ""
echo "Log file: /var/log/stackscript.log"
echo "Completed at: $(date)"
