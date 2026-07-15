# Installation

This guide installs the CamperPilot base system on a Raspberry Pi 4.

The current CamperPilot installer installs the system scripts and required sudoers configuration. Project-specific openHAB configuration will be added later.

---

## Requirements

* Raspberry Pi 4 with at least 2 GB RAM
* 64-bit capable microSD card, preferably an endurance model
* Stable Raspberry Pi power supply
* Ethernet connection for the initial installation
* Computer with Raspberry Pi Imager
* Access to the local network router

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

Change the default password during the base configuration.

---

## 5. Configure the Base System

Start the openHABian configuration tool:

```bash
sudo openhabian-config
```

Configure at least the following settings.

### Hostname

Select:

```text
30 | System Settings
31 | Change hostname
```

Recommended hostname:

```text
camperpilot
```

Restart the Raspberry Pi:

```bash
sudo reboot
```

The system should then be available at:

```text
http://camperpilot:8080
```

### Time Zone

Select:

```text
30 | System Settings
33 | Set system timezone
```

For Germany:

```text
Europe/Berlin
```

### Passwords

Select:

```text
30 | System Settings
34 | Change passwords
```

Change at least the password of the `openhabian` system user.

---

## 6. Verify the Base Installation

Check the hostname:

```bash
hostname
```

Expected result:

```text
camperpilot
```

Check whether openHAB is running:

```bash
sudo systemctl is-active openhab
```

Expected result:

```text
active
```

Check whether the operating system is running in 64-bit mode:

```bash
getconf LONG_BIT
```

Expected result:

```text
64
```

Open the openHAB interface:

```text
http://camperpilot:8080
```

---

## 7. Configure Remote Access

Configure secure remote access using Tailscale:

[`Remote Access with Tailscale`](remote-access.md)

No ports should be forwarded from the mobile router to CamperPilot.

---

## 8. Install CamperPilot

Download the current installer:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/knxhelden/CamperPilot/main/install.sh \
  -o /tmp/camperpilot-install.sh
```

Make it executable:

```bash
chmod +x /tmp/camperpilot-install.sh
```

Run the installer:

```bash
sudo /tmp/camperpilot-install.sh
```

The installer opens a main menu with the following options:

```text
1) Install
2) Uninstall
```

Choose **Install** to install or update the CamperPilot system scripts and sudoers configuration. Choose **Uninstall** to remove these CamperPilot system files again. Installer messages are color-coded: green marks successful steps, yellow marks warnings or follow-up checks, and red marks showstoppers. For scripted runs, the same actions can be selected directly:

```bash
sudo /tmp/camperpilot-install.sh install
sudo /tmp/camperpilot-install.sh uninstall
```

The installer downloads the current CamperPilot repository into a `CamperPilot` subdirectory next to the installer. The main installer dispatches to the dedicated step file `installer/steps/system_scripts.sh` for system scripts and sudoers configuration. It installs:

```text
/usr/local/sbin/camperpilot-poweroff
/usr/local/sbin/camperpilot-reboot
/etc/sudoers.d/camperpilot-openhab
```

The system scripts are installed with:

```text
Owner:       root:root
Permissions: 750
```

The sudoers configuration is installed with:

```text
Owner:       root:root
Permissions: 440
```

The installer can be executed again to update the local `CamperPilot` checkout and refresh the installed files. Manual copying from the `scripts/` directory is not required.

---

## Installation Status

The base installation is complete when:

* openHAB is accessible
* SSH access works
* the hostname is `camperpilot`
* the default password has been changed
* the correct time zone is configured
* Tailscale remote access works
* the CamperPilot installer completes successfully

The current installer only installs the system scripts and sudoers configuration. Bindings, Things, Items, rules and additional system components will be added incrementally.
