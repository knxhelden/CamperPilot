# CamperPilot System Scripts

This directory contains system-level scripts used by CamperPilot and openHAB.

The scripts must be installed in:

```text
/usr/local/sbin/
```

Available scripts:

| Script                 | Purpose                           |
| ---------------------- | --------------------------------- |
| `camperpilot-poweroff` | Safely shuts down the CamperPilot |
| `camperpilot-reboot`   | Safely reboots the CamperPilot    |

Install the scripts:

```bash
sudo cp camperpilot-poweroff camperpilot-reboot /usr/local/sbin/
sudo chown root:root /usr/local/sbin/camperpilot-*
sudo chmod 755 /usr/local/sbin/camperpilot-*
```

The scripts intentionally use no file extension, as they are installed as executable system commands.
