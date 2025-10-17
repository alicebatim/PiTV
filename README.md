# PiTV – Raspberry Pi AP‑STA Access Point with Tvheadend

This project turns a Raspberry Pi into a self healing Wi-Fi access point that also runs Tvheadend for Freeview/DVB streaming.  
Clients can connect to the Pi’s SSID (`PiTV`), get an IP in the `192.168.50.x` range, and immediately access Tvheadend at:

http://pitv:9981


---

## Features

- AP‑STA mode: Pi connects upstream to your home Wi‑Fi (`wlan0`) while simultaneously running an AP (`wlan0_ap`).
- DHCP/DNS: `dnsmasq` provides leases and resolves `pitv` → `192.168.50.1`.
- NAT/Forwarding: Clients on the AP get full internet access via masquerading.
- Self‑healing: A systemd unit + timer recreates `wlan0_ap` and restarts `hostapd`/`dnsmasq` if the AP fails.
- Tvheadend: Installed and accessible at `http://pitv:9981` for live TV streaming and recording.

---

## Installation

Clone this repo and run the setup script on a fresh Raspberry Pi OS Lite:

```
```
bash
git clone https://github.com/yourname/pitv.git

cd pitv

chmod +x setup-pitv.sh
./setup-pitv.sh

Reboot when finished.

WiFi Access Point
• 	SSID: 
• 	Passphrase:  (set in )
• 	Subnet: 
• 	Gateway/DNS: 

Tvheadend Setup
Tvheadend is installed automatically. 

After reboot:

1. 	Connect a DVB T/T2 tuner (e.g. Raspberry Pi TV HAT).
2. 	From a client on the PiTV AP, 

open:

```http://pitv:9981```

3. 	Log in with the admin credentials you set during installation.
4. 	Follow the wizard:

• 	Select your tuner under Configuration → DVB Inputs → TV Adapters.

• 	Create a DVB-T Network for your region.

• 	Add muxes (frequencies) for your transmitter (Tvheadend can auto populate).

• 	Scan muxes → discover services → map services to channels.

5. 	Test streaming by clicking the play icon next to a channel.

Access Control

By default, Tvheadend requires login. You can allow LAN clients automatically:

• 	Edit :
``` /home/hts/.hts/tvheadend/accesscontrol/lan.json```
• 	Restart Tvheadend:
```sudo systemctl restart tvheadend```

Clients

• 	Kodi: Enable the Tvheadend PVR Client add‑on, point it to .

• 	VLC: Open .

• 	Browser: Use the Tvheadend web UI for EPG and streaming.

Self‑Healing

• 	 `wlan0_ap-heal.service` ensures the AP interface is recreated if it disappears.

• 	 `wlan0_ap-heal.timer` runs every 60s to check and repair automatically.

Repository Contents

• 	 `setup-pitv.sh` one‑shot installer for AP‑STA, NAT, dnsmasq, hostapd, Tvheadend, and self‑healing.

• 	 – this file.

Roadmap

• 	Pre‑seed Tvheadend muxes for UK Freeview to make setup fully headless.