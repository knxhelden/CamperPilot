# Installation

This guide installs the CamperPilot base system on a Raspberry Pi 4.

The current CamperPilot installer configures the base hostname, time zone and `openhabian` password, then installs the system scripts and required sudoers configuration. Project-specific openHAB configuration will be added later.

---

## 1. Write openHABian to the SD Card

Open **Raspberry Pi Imager** and select:

```text
Device:
Raspberry Pi 4

Operating System:
Other specific-purpose OS
└── Home assistants and home automation
    └── openHAB
        └── openHABian 64-bit

Storage:
Your microSD card
```

Write the image to the SD card.

> All existing data on the selected SD card will be deleted.

---

## 2. Start the Raspberry Pi

1. Insert the SD card into the Raspberry Pi.
2. Connect the Raspberry Pi to the router using Ethernet.
3. Connect the power supply.
4. Wait for the initial installation to complete.

The first installation usually takes between 10 and 30 minutes.

Installation progress can be viewed at:

```text
http://openhabian:81
```

Alternatively, use the IP address assigned by the router:

```text
http://<IP-ADDRESS>:81
```

Do not disconnect the power supply while the installation is running.

---

## 3. Open openHAB

After the installation has completed, open:

```text
http://openhabian:8080
```

Alternatively, use the IP address:

```text
http://<IP-ADDRESS>:8080
```

Complete the initial openHAB setup and create the administrator account.

---

## 4. Connect through SSH

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

## 5. Configure Remote Access

Configure secure remote access using Tailscale:

[`Remote Access with Tailscale`](remote-access.md)

No ports should be forwarded from the mobile router to CamperPilot.

---

## 6. Install CamperPilot

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
sudo /tmp/camperpilot_installer.sh install
sudo /tmp/camperpilot_installer.sh --install
sudo /tmp/camperpilot_installer.sh uninstall
sudo /tmp/camperpilot_installer.sh --uninstall
sudo /tmp/camperpilot_installer.sh -h
sudo /tmp/camperpilot_installer.sh --help
```

Available actions:

* `install` or `--install`: install CamperPilot without opening the menu.
* `uninstall` or `--uninstall`: remove CamperPilot again without opening the menu.
* `-h` or `--help`: show the installer help text.
