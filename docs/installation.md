# Installation

This guide installs the CamperPilot base system on a Raspberry Pi 4.

The current CamperPilot installer:

- Configures the base system (e.g. hostname, time zone and `openhabian` password).
- Installs the CamperPilot system bash scripts and required sudoers configuration.
- Provisions the project-specific openHAB configuration (e.g. bindings, things, items, sitemap, automation rules, etc.).
- Configures optional hardware integrations for
  - **Zigbee**,
  - **Bluetooth**,
  - **Mopeka Pro gas level sensor**

---

## 1. Write openHABian to the SD Card

Open [Raspberry Pi Imager](https://www.raspberrypi.com/software/) and select:

```text
Device:
Raspberry Pi 4

Operating System:
Other specific-purpose OS
└── Home automation
    └── openHAB
        └── openHABian 64-bit

Storage:
Your microSD card
```

Write the image to the SD card.

---

## 2. Start the Raspberry Pi and open openHAB

1. Insert the SD card into the Raspberry Pi.
2. Connect the Raspberry Pi to the router using Ethernet.
3. Connect the power supply.
4. Wait for the initial installation to complete (this takes approx. 10 minutes).
5. After the installation has completed, open: `http://openhabian:8080`
6. Complete the initial openHAB setup and create the administrator account.

---

## 3. Connect through SSH

Connect to the Raspberry Pi:

```bash
ssh openhabian@openhabian
```

Alternatively, use its IP address:

```bash
ssh openhabian@<IP-ADDRESS>
```

Default credentials:

```text
Username: openhabian
Password: openhabian
```

Change the default password during the CamperPilot installation.

---

## 4. Configure Remote Access

Configure secure remote access using [Tailscale](remote-access.md).

No ports should be forwarded from the mobile router to CamperPilot.

---

## 5. Install CamperPilot

The installer installs everything required for CamperPilot. Run the following commands on the Raspberry Pi.

Download the current installer:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/knxhelden/CamperPilot/main/installer/camperpilot_installer.sh \
  -o /tmp/camperpilot_installer.sh
```

Make it executable:

```bash
chmod +x /tmp/camperpilot_installer.sh
```

Run the installer:

```bash
sudo /tmp/camperpilot_installer.sh
```

Choose **Install** from the installer menu.

You can also pass an action directly to the installer:

```bash
sudo /tmp/camperpilot_installer.sh --install
sudo /tmp/camperpilot_installer.sh --uninstall
sudo /tmp/camperpilot_installer.sh --help
```

Available actions:

* `--install` or `--uninstall`: install / uninstall CamperPilot without opening the menu.
* `-h` or `--help`: show the installer help text.
