# CamperPilot System Scripts

This directory contains the system-level helper files installed by `installer/camperpilot_installer.sh`.
Manual installation from this directory is not required.

| File                   | Purpose                                                                 |
| ---------------------- | ----------------------------------------------------------------------- |
| `camperpilot-poweroff` | Shutdown helper that logs the request, syncs the filesystem and powers off the Raspberry Pi. |
| `camperpilot-reboot`   | Reboot helper that logs the request, syncs the filesystem and restarts the Raspberry Pi. |
| `camperpilot-openhab`  | sudoers configuration that allows the `openhab` user to run the two helper scripts without a password. |

The installer copies the helper scripts to `/usr/local/sbin/` and the sudoers configuration to `/etc/sudoers.d/` with the required owner and permissions.
