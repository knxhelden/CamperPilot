# Installation

This guide installs the CamperPilot base system on a Raspberry Pi 4.

The current CamperPilot installer configures the base hostname, time zone and `openhabian` password, installs the system scripts and required sudoers configuration, and provisions the project-specific openHAB configuration including JavaScript automation rules.

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

The installer then asks whether Zigbee will be used. Answering **No** (the
default) skips the optional `zigbee.things` configuration; no Zigbee
coordinator is required in that case. Answer **Yes** only when CamperPilot
should use a Zigbee coordinator.

### Zigbee coordinator configuration

When Zigbee is enabled at the installer prompt, the `openhab/things/zigbee.things` source file is provisioned with target-system values before it is copied to `/etc/openhab/things/zigbee.things`.

The installer individualizes these values:

* `zigbee_port`: automatically detected when exactly one device exists under `/dev/serial/by-id`.
* `zigbee_panid`: reused from an existing installed `zigbee.things`, or generated for a new installation.
* `zigbee_extendedpanid`: reused from an existing installed `zigbee.things`, or generated for a new installation.
* `zigbee_networkkey`: reused from an existing installed `zigbee.things`, or generated for a new installation.

The generated network values should stay stable after devices have been paired. If you already have a Zigbee network, set the existing values explicitly during installation:

```bash
sudo env \
  CAMPERPILOT_ZIGBEE_PORT=/dev/serial/by-id/<zigbee-device> \
  CAMPERPILOT_ZIGBEE_PAN_ID=<pan-id> \
  CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID=<extended-pan-id> \
  CAMPERPILOT_ZIGBEE_NETWORK_KEY=<network-key> \
  /tmp/camperpilot_installer.sh install
```

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
* `uninstall` or `--uninstall`: remove the CamperPilot system scripts
  (`camperpilot-poweroff` and `camperpilot-reboot`) and the
  `camperpilot-openhab` sudoers configuration without opening the menu. It also
  completely removes the `CamperPilot` repository cloned next to the installer.
  The openHAB configuration files under `/etc/openhab` are deliberately
  retained because they may contain manual changes. The installer prints a
  warning with the files that should be reviewed and, if appropriate, removed
  manually.
* `-h` or `--help`: show the installer help text.
