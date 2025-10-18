#!/bin/bash
set -e

# ============================================================
# PiTV AP-STA Setup Script
# ------------------------------------------------------------
# This script configures a Raspberry Pi to act as a dual-role
# Wi-Fi device:
#   - wlan0: connects upstream to your home Wi-Fi (STA mode)
#   - wlan0_ap: provides a local access point (AP mode)
#
# It installs and configures:
#   - systemd-networkd (for clean interface separation)
#   - dnsmasq (for DHCP/DNS on the AP subnet)
#   - hostapd (for the Wi-Fi access point)
#   - iptables-persistent (for NAT/masquerading)
#
# It also creates a self-healing systemd unit + timer that
# automatically repairs the AP interface if it disappears.
#
# Result: Clients can connect to SSID "PiTV", get an IP in
# 192.168.50.x, and reach the internet via NAT through wlan0.
# ============================================================

echo "[*] Updating system and installing packages..."
sudo apt update && sudo apt install -y hostapd dnsmasq iw iptables-persistent systemd-networkd

# ------------------------------------------------------------
# Configure systemd-networkd
# ------------------------------------------------------------
# wlan0: DHCP client for upstream Wi-Fi
# wlan0_ap: static IP 192.168.50.1/24 for AP subnet
echo "[*] Configuring systemd-networkd..."
cat <<EOF | sudo tee /etc/systemd/network/10-wlan0.network
[Match]
Name=wlan0

[Network]
DHCP=yes
EOF

cat <<EOF | sudo tee /etc/systemd/network/20-wlan0_ap.network
[Match]
Name=wlan0_ap

[Network]
Address=192.168.50.1/24
EOF

sudo systemctl enable systemd-networkd

# ------------------------------------------------------------
# Configure dnsmasq
# ------------------------------------------------------------
# Provides DHCP leases and DNS for AP clients.
# - Range: 192.168.50.50–150
# - Gateway: 192.168.50.1
# - DNS: Pi itself + Cloudflare fallback
# - Alias: "pitv" resolves to 192.168.50.1
echo "[*] Configuring dnsmasq..."
cat <<EOF | sudo tee /etc/dnsmasq.d/pitv.conf
interface=wlan0_ap
dhcp-range=192.168.50.50,192.168.50.150,12h
dhcp-option=3,192.168.50.1
dhcp-option=6,192.168.50.1,1.1.1.1
address=/pitv/192.168.50.1
EOF

# ------------------------------------------------------------
# Configure hostapd
# ------------------------------------------------------------
# Defines the AP SSID, channel, and WPA2 key.
# SSID: PiTV
# WPA2 passphrase: YourStrongPassword
echo "[*] Configuring hostapd..."
cat <<EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0_ap
ssid=PiTV
hw_mode=g
channel=1
wmm_enabled=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=YourStrongPassword
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

sudo sed -i 's|#DAEMON_CONF="".*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# ------------------------------------------------------------
# Enable IP forwarding
# ------------------------------------------------------------
# Allows traffic from AP clients to be routed out via wlan0.
echo "[*] Enabling IP forwarding..."
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
# ------------------------------------------------------------
# Disable IPv6 (prevents route/gateway leaks and Android "No Internet")
# ------------------------------------------------------------
echo "[*] Disabling IPv6 system-wide and on AP interfaces..."

# Remove any old disable_ipv6 entries from sysctl.conf
sudo sed -i '/disable_ipv6/d' /etc/sysctl.conf

# Disable IPv6 permanently
cat <<EOF | sudo tee -a /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
net.ipv6.conf.wlan0.disable_ipv6=1
net.ipv6.conf.wlan0_ap.disable_ipv6=1
EOF

# Apply changes immediately
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.wlan0.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.wlan0_ap.disable_ipv6=1

# Flush any existing IPv6 addresses
sudo ip -6 addr flush dev wlan0
sudo ip -6 addr flush dev wlan0_ap



# Bug The Raspberry Pi’s AP/STA dual-Wi-Fi setup was leaking the upstream network’s default gateway to clients connected to the access point.
# House router
# ------------------------------------------------------------
# Configure NAT
# ------------------------------------------------------------
# Masquerades AP client traffic out through wlan0.
# echo "[*] Configuring NAT..."
# sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
# sudo netfilter-persistent save
# ------------------------------------------------------------
# Configure NAT & packet forwarding (FIXED)
# ------------------------------------------------------------
# ------------------------------------------------------------
# Enable IPv4 forwarding
# ------------------------------------------------------------
echo "[*] Enabling IPv4 forwarding..."
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -w net.ipv4.ip_forward=1

# ------------------------------------------------------------
# Disable IPv6 (prevents gateway advertisement leaks and Android 'No Internet')
# ------------------------------------------------------------
echo "[*] Disabling IPv6 system-wide and on AP interfaces..."
sudo sed -i '/disable_ipv6/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.wlan0.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.wlan0_ap.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf

# Apply immediately
sudo sysctl -p

# ------------------------------------------------------------
# Configure NAT & packet forwarding (clean, safe)
# ------------------------------------------------------------
echo "[*] Configuring NAT and forwarding..."

# Flush existing rules
sudo iptables -F
sudo iptables -t nat -F

# Set default FORWARD policy to DROP (blocks all by default)
sudo iptables -P FORWARD DROP

# Allow AP → upstream traffic
sudo iptables -A FORWARD -i wlan0_ap -o wlan0 -j ACCEPT

# Allow return traffic from upstream → AP
sudo iptables -A FORWARD -i wlan0 -o wlan0_ap -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT only traffic from the AP subnet out wlan0
sudo iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o wlan0 -j MASQUERADE

# Persist rules across reboots
sudo netfilter-persistent save
sudo netfilter-persistent reload

echo "[*] IPv4 forwarding, IPv6 disable, and NAT rules applied."

# ------------------------------------------------------------
# Self-healing systemd unit
# ------------------------------------------------------------
# Creates wlan0_ap if missing, assigns IP, and restarts
# hostapd + dnsmasq. Timer runs every 60s to ensure AP stays up.
echo "[*] Creating self-healing systemd unit..."
cat <<EOF | sudo tee /etc/systemd/system/wlan0_ap-heal.service
[Unit]
Description=Self-healing AP stack (wlan0_ap + hostapd + dnsmasq)
After=network.target
Wants=hostapd.service dnsmasq.service

[Service]
Type=oneshot
# Bring down and remove any old AP interface
ExecStartPre=/sbin/ip link set wlan0_ap down 2>/dev/null || true
ExecStartPre=/sbin/iw dev wlan0_ap del 2>/dev/null || true

# Create AP interface
ExecStart=/sbin/iw dev wlan0 interface add wlan0_ap type __ap

# Assign static IP and bring up
ExecStartPost=/sbin/ip addr add 192.168.50.1/24 dev wlan0_ap
ExecStartPost=/sbin/ip link set wlan0_ap up

# Apply IPv4 forwarding
ExecStartPost=/sbin/sysctl -w net.ipv4.ip_forward=1

# Disable IPv6 on all relevant interfaces
ExecStartPost=/sbin/sysctl -w net.ipv6.conf.all.disable_ipv6=1
ExecStartPost=/sbin/sysctl -w net.ipv6.conf.default.disable_ipv6=1
ExecStartPost=/sbin/sysctl -w net.ipv6.conf.lo.disable_ipv6=1
ExecStartPost=/sbin/sysctl -w net.ipv6.conf.wlan0.disable_ipv6=1
ExecStartPost=/sbin/sysctl -w net.ipv6.conf.wlan0_ap.disable_ipv6=1

# Configure clean NAT & forwarding rules
ExecStartPost=/sbin/iptables -F
ExecStartPost=/sbin/iptables -t nat -F
ExecStartPost=/sbin/iptables -P FORWARD DROP
ExecStartPost=/sbin/iptables -A FORWARD -i wlan0_ap -o wlan0 -j ACCEPT
ExecStartPost=/sbin/iptables -A FORWARD -i wlan0 -o wlan0_ap -m state --state ESTABLISHED,RELATED -j ACCEPT
ExecStartPost=/sbin/iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o wlan0 -j MASQUERADE
ExecStartPost=/usr/sbin/netfilter-persistent save

# Start AP services
ExecStartPost=/bin/systemctl restart hostapd
ExecStartPost=/bin/systemctl restart dnsmasq

RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

EOF

cat <<EOF | sudo tee /etc/systemd/system/wlan0_ap-heal.timer
[Unit]
Description=Periodic check & heal for wlan0_ap

[Timer]
OnBootSec=30
OnUnitActiveSec=60

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable wlan0_ap-heal.service wlan0_ap-heal.timer
sudo systemctl enable hostapd dnsmasq

echo "[*] Setup complete. Reboot to activate PiTV AP."
#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