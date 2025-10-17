I see what’s happening, Vaughan — your Markdown is almost right, but a few formatting details are tripping you up. GitHub’s Markdown renderer is strict about code fences, tables, and section breaks. Let me show you a clean, corrected version of your README that will render exactly as you expect.

# PiTV – Raspberry Pi AP‑STA Access Point with Tvheadend

This project turns a Raspberry Pi into a self‑healing Wi‑Fi access point that also runs Tvheadend for Freeview/DVB streaming.  
Clients can connect to the Pi’s SSID (`PiTV`), get an IP in the `192.168.50.x` range, and immediately access Tvheadend at:

[http://pitv:9981](http://pitv:9981)

---

## Features

- AP‑STA mode: Pi connects upstream to your home Wi‑Fi (`wlan0`) while simultaneously running an AP (`wlan0_ap`).
- DHCP/DNS: `dnsmasq` provides leases and resolves `pitv` → `192.168.50.1`.
- NAT/Forwarding: Clients on the AP get full internet access via masquerading.
- Self‑healing: A systemd unit + timer recreates `wlan0_ap` and restarts `hostapd`/`dnsmasq` if the AP fails.
- Tvheadend: Installed and accessible at [http://pitv:9981](http://pitv:9981) for live TV streaming and recording.

---

## Installation

Clone this repo and run the setup script on a fresh Raspberry Pi OS Lite:

```bash
git clone https://github.com/yourname/pitv.git
cd pitv
chmod +x setup-pitv.sh
./setup-pitv.sh


Reboot when finished.

Wi‑Fi Access Point
|  |  | 
|  |  | 
|  |  | 
|  |  | 
|  |  | 



Tvheadend Setup
Tvheadend is installed automatically. After reboot:
- Connect a DVB‑T/T2 tuner (for example, Raspberry Pi TV HAT).
- From a client on the PiTV AP, open:
http://pitv:9981
- Log in with the admin credentials you set during installation.
- Follow the setup wizard:
- Select your tuner under Configuration → DVB Inputs → TV Adapters.
- Create a DVB‑T Network for your region.
- Add muxes (frequencies) for your transmitter (Tvheadend can auto‑populate).
- Scan muxes, discover services, and map services to channels.
- Test streaming by clicking the play icon next to a channel.

Access Control
By default, Tvheadend requires login. To allow LAN clients automatically:
Edit the access control configuration file:
/home/hts/.hts/tvheadend/accesscontrol/lan.json


Example content:
{
  "enabled": true,
  "username": "lan",
  "password": "",
  "prefix": "192.168.50.0/24",
  "streaming": true,
  "dvr": true,
  "htsp": true,
  "admin": true
}


Then restart Tvheadend:
sudo systemctl restart tvheadend



Clients
|  |  | 
|  | http://pitv:9981 | 
|  | http://pitv:9981/playlist/channels | 
|  |  | 



Self‑Healing Services
- wlan0_ap-heal.service ensures the AP interface is recreated if it disappears.
- wlan0_ap-heal.timer runs every 60 seconds to check and repair automatically.

Repository Contents
|  |  | 
|  |  | 
|  |  | 



Roadmap
- Pre‑seed Tvheadend muxes for UK Freeview to enable full headless setup.
- Add optional Jellyfin integration for richer client playback.
- Improve AP monitoring and automatic upstream reconnect logic.

PiTV — portable Freeview and DVB streaming from your Raspberry Pi.

---

### Why your earlier Markdown “looked wrong”
- You had **nested code fences** (` ``` ```bash`) which broke rendering. Always start with ```bash and end with ``` on its own line.  
- Tables need **pipes (`|`) and headers** to render properly.  
- Plain text lists like “Wi‑Fi Access Point / Setting / Value” won’t format as a table without Markdown table syntax.  

This corrected version will render perfectly on GitHub.  

Would you like me to also generate a **ready‑to‑drop `lan.json` file** so you can commit it alongside this README for a fully headless Tvheadend setup?


