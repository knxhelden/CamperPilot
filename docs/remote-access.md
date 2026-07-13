# Remote Access with Tailscale

CamperPilot uses **Tailscale** for secure remote access.

## Why Tailscale?

Mobile LTE and 5G connections often do not provide a publicly reachable IPv4 address. Traditional remote access using port forwarding and Dynamic DNS may therefore not work.

Tailscale creates a private network between authorized devices and provides each device with a stable IP address and hostname. No SSH or openHAB ports need to be exposed publicly.

**No router configuration, port forwarding or Dynamic DNS is required.**

---

## Requirements

* CamperPilot running openHABian
* Local SSH access for the initial setup
* A Tailscale account
* Tailscale installed on the laptop or mobile device

---

## 1. Create a Tailscale Auth Key

Open the Tailscale Admin Console and create an authentication key:

1. Open **Keys**
2. Select **Generate auth key**
3. Create a **one-off** key
4. Do not enable **Ephemeral**
5. Copy the generated key

The key is only required during installation and must not be stored in the repository.

---

## 2. Install Tailscale on CamperPilot

Connect to CamperPilot through SSH and open the openHABian configuration tool:

```bash
sudo openhabian-config
```

Select:

```text
30 | System Settings
3B | Setup Tailscale VPN
```

Confirm the installation and enter the previously generated Tailscale auth key.

openHABian installs Tailscale and connects CamperPilot to the Tailscale network.

---

## 3. Verify the Connection

Run:

```bash
tailscale status
```

Display the assigned Tailscale IP address:

```bash
tailscale ip -4
```

Check the service:

```bash
sudo systemctl is-active tailscaled
```

The expected result is:

```text
active
```

---

## 4. Connect from a Laptop

Install Tailscale on the laptop and sign in with the same Tailscale account.

When MagicDNS is enabled, CamperPilot can be reached using its hostname:

```bash
ssh <username>@camperpilot
```

Open the openHAB interface:

```text
http://camperpilot:8080
```

Alternatively, use the Tailscale IP address:

```bash
ssh <username>@100.x.y.z
```

```text
http://100.x.y.z:8080
```

MagicDNS automatically assigns hostnames to devices inside the Tailscale network.

---

## Optional: Disable Key Expiry

For a permanently installed CamperPilot, automatic device key expiry can interrupt remote access.

The expiry can be disabled in the Tailscale Admin Console:

```text
Machines → camperpilot → Disable key expiry
```

Only disable expiry for trusted devices. Remove the device from Tailscale immediately if the Raspberry Pi is lost or replaced.

---

## Troubleshooting

Check whether CamperPilot is connected:

```bash
tailscale status
```

Restart Tailscale:

```bash
sudo systemctl restart tailscaled
```

If CamperPilot was removed from the Tailscale network, create a new one-off auth key and run the openHABian Tailscale setup again.

Both devices must:

* be connected to the internet
* run Tailscale
* belong to the same Tailscale network
* be shown as online in the Tailscale Admin Console

---

## Security Notes

* Never commit Tailscale auth keys to GitHub.
* Do not expose ports `22` or `8080` through the mobile router.
* Only add trusted users and devices to the Tailscale network.
