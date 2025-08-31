# Tailscale Exit Node StackScript for Linode

This StackScript automatically configures a Linode instance as a Tailscale Exit Node, allowing you to route your internet traffic through your Linode server when connected to Tailscale.

[![Tailscale](https://img.shields.io/badge/Tailscale-Compatible-blue)](https://tailscale.com)
[![Linode](https://img.shields.io/badge/Linode-StackScript-green)](https://www.linode.com/stackscripts/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04-orange)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-10%20%7C%2011-red)](https://www.debian.org/)
## Features

- 🚀 One-click setup of a Tailscale Exit Node on Linode
- 🔒 Proper firewall configuration with firewalld
- 🌐 Automatic IP forwarding configuration
- 🖥️ Optional SSH access via Tailscale network
- 📝 Comprehensive logging for troubleshooting

## Prerequisites

1. A Linode account
2. A Tailscale account
3. A Tailscale auth key (generated from the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys))

## Quick Setup

1. Log in to your Linode account
2. Create a new Linode instance
3. Select "StackScripts" from the Create tab
4. Choose "Community StackScripts" and search for "Tailscale Exit Node"
5. Select this StackScript and fill in the required fields:
   - **Tailscale Auth Key**: Your Tailscale auth key
   - **Hostname**: A name for your Exit Node (default: Tailscale-Gateway)
   - **Enable SSH access via Tailscale**: Choose whether to allow SSH from Tailscale network (yes/no)

## Usage

Once the Linode is deployed and the script completes:

1. Approve the Exit Node in the Tailscale admin console: 
   https://login.tailscale.com/admin/machines

2. To use this Exit Node from any of your Tailscale-connected devices, run:
   ```
   tailscale up --exit-node=<hostname>
   ```
   or
   ```
   tailscale up --exit-node=<tailscale-ip>
   ```

3. To check the Exit Node status:
   ```
   tailscale status
   tailscale exit-node list
   ```

## Authentication Key Tips

- Use a **reusable** auth key if you plan to redeploy this script multiple times
- For improved security, set an expiration time on your auth key
- Consider using a key with limited permissions (only node registration)

## Troubleshooting

- Check the log file at `/var/log/stackscript.log` for detailed script execution output
- Verify Tailscale status with `tailscale status`
- Check system logs with `journalctl -u tailscaled`
- Ensure firewalld is properly configured with `firewall-cmd --list-all`

## Security Considerations

- This script configures your Linode as an internet gateway for your Tailscale network
- All traffic from connected devices can potentially route through this server when used as an Exit Node
- Consider implementing additional security measures based on your requirements

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This script is provided under the MIT License. See the LICENSE file for details.

## Acknowledgements

- [Tailscale](https://tailscale.com/) for their excellent VPN solution
- [Linode](https://www.linode.com/) for their cloud hosting platform
