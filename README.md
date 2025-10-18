# PiTV – Raspberry Pi AP‑STA Access Point with Tvheadend

This project turns a **Raspberry Pi Zero 2 W** into a self-healing Wi-Fi access point that also runs **Tvheadend** for Freeview/DVB streaming.  
Clients can connect to the Pi’s SSID (`PiTV`), get an IP in the `192.168.50.x` range, and immediately access Tvheadend at:

[http://pitv:9981](http://pitv:9981)

---

## Features

- **AP‑STA Mode**: Pi connects upstream to your home Wi-Fi (`wlan0`) while simultaneously running an AP (`wlan0_ap`).
- **DHCP/DNS**: `dnsmasq` provides leases and resolves `pitv` → `192.168.50.1`.
- **NAT/Forwarding**: Clients on the AP get full internet access via NAT/masquerading.
- **Self-Healing**: A systemd unit + timer recreates `wlan0_ap` and restarts `hostapd`/`dnsmasq` if the AP fails.
- **Tvheadend**: Installed and accessible at `http://pitv:9981` for live TV streaming and recording.
- **IPv6 Disabled**: Prevents Android “No Internet” warnings and gateway leaks.

---

## Installation

Clone this repository and run the setup script on a fresh **Raspberry Pi OS Lite** installation:

```bash
git clone https://github.com/yourname/pitv.git
cd pitv
chmod +x setup-pitv.sh
./setup-pitv.sh
```

**Reboot** after the script completes.

---

## Wi-Fi Access Point

* **SSID:** PiTV  
* **Passphrase:** `YourStrongPassword` (set in `setup-pitv.sh`)  
* **Subnet:** 192.168.50.0/24  
* **Gateway/DNS:** 192.168.50.1  

---

## Tvheadend Setup

Tvheadend is installed automatically. After reboot:

1. Connect a DVB-T/T2 tuner (e.g., Raspberry Pi TV HAT).  
2. From a client on the PiTV AP, open: [http://pitv:9981](http://pitv:9981)  
3. Log in with the admin credentials you set during installation.  
4. Follow the wizard:

   * Select your tuner under **Configuration → DVB Inputs → TV Adapters**.  
   * Create a DVB-T network for your region.  
   * Add muxes (frequencies) for your transmitter (Tvheadend can auto-populate).  
   * Scan muxes → discover services → map services to channels.  

5. Test streaming by clicking the **play icon** next to a channel.

---

## Client Setup

* **Kodi**: Enable the Tvheadend PVR Client add-on, point it to `http://pitv:9981`.  
* **VLC**: Open network stream using `http://pitv:9981/stream/channelid`.  
* **Browser**: Use the Tvheadend web UI for EPG and streaming.  

---

## Self-Healing

* `wlan0_ap-heal.service` ensures the AP interface is recreated if it disappears.  
* `wlan0_ap-heal.timer` runs every 60s to check and repair automatically.  

---

## Backup & Restore

You can easily backup and restore your PiTV configuration, including **network settings, iptables rules, and system tweaks**, using the provided scripts.

### Backup

Run the backup script to save the current configuration to your local Git repository:

```bash
cd ~/PiTV
./backup.sh
```

This script saves:

- `dnsmasq` configuration  
- `hostapd` configuration  
- `systemd-networkd` files  
- `sysctl.conf` (IP forwarding, IPv6 settings)  
- `iptables` rules (filter + NAT)  
- Self-healing systemd unit (`wlan0_ap-heal.service` and timer)  

> ⚠️ Make sure Git is configured with your user/email and you have remote access set up before pushing.

### Restore

To restore a previous configuration:

1. Pull the latest backup from your Git repository:

```bash
cd ~/PiTV
git pull
```

2. Copy the backed-up configuration files to the correct system locations:

```bash
sudo cp backup/dnsmasq.conf /etc/dnsmasq.d/pitv.conf
sudo cp backup/hostapd.conf /etc/hostapd/hostapd.conf
sudo cp backup/10-wlan0.network /etc/systemd/network/
sudo cp backup/20-wlan0_ap.network /etc/systemd/network/
sudo cp backup/sysctl.conf /etc/sysctl.conf
sudo cp backup/wlan0_ap-heal.service /etc/systemd/system/
sudo cp backup/wlan0_ap-heal.timer /etc/systemd/system/
sudo cp backup/iptables.rules /etc/iptables/rules.v4
```

3. Reload systemd and apply configurations:

```bash
sudo systemctl daemon-reload
sudo systemctl restart systemd-networkd
sudo systemctl restart hostapd dnsmasq
sudo netfilter-persistent reload
sudo sysctl -p
```

4. Reboot the Pi to ensure all changes take effect:

```bash
sudo reboot
```

**Notes:**

- Make sure no clients are connected to the AP during restore to avoid conflicts.  
- Backups can be version-controlled in Git for easy rollback.  
- The backup script can be scheduled via `cron` or a systemd timer for regular snapshots.  

---

## Repository Contents

* `setup-pitv.sh` – One-shot installer for AP‑STA, NAT, `dnsmasq`, `hostapd`, Tvheadend, and self-healing.  
* `README.md` – This file.  

---

## Roadmap



---

## Notes

* The setup disables IPv6 to avoid Android “No Internet” warnings.  
* NAT/iptables rules are configured to prevent gateway leaks.  
* Make sure your upstream Wi-Fi (`wlan0`) is functional before running the AP.
