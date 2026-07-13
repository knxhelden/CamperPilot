# 🚐 CamperPilot

> A Raspberry Pi–powered monitoring and automation platform for camper vans and motorhomes.

![Status](https://img.shields.io/badge/Status-Active%20Development-2ea44f)
![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi%204-c51a4a)
![Automation](https://img.shields.io/badge/Automation-openHAB-ff8c00)
![Remote Access](https://img.shields.io/badge/Remote%20Access-Tailscale-242424)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## ✨ Overview

**CamperPilot** is a private DIY project that turns a camper van or motorhome into a connected, monitorable and partially automated living space.

The system is based on a Raspberry Pi running openHABian and openHAB. It combines local automation, environmental monitoring, vehicle-related sensors and secure remote access.

CamperPilot is designed to continue operating locally even when no mobile internet connection is available.

---

## 🎯 Project Goals

CamperPilot is intended to provide:

* local monitoring and automation with openHAB
* temperature and climate monitoring
* door and window monitoring
* intrusion-related notifications
* battery and power monitoring
* gas level monitoring
* vehicle inclination and leveling support
* GPS position and telemetry
* local dashboards inside the camper
* secure remote maintenance through Tailscale
* notifications through the camper's mobile internet connection

---

## 🏗️ Architecture

The current platform is built around the following components:

| Component              | Purpose                                                    |
| ---------------------- | ---------------------------------------------------------- |
| **Raspberry Pi 4**     | Main CamperPilot controller                                |
| **openHABian**         | Raspberry Pi operating system and installation platform    |
| **openHAB**            | Automation, rules, dashboards and device integration       |
| **Mosquitto**          | MQTT message broker                                        |
| **Tailscale**          | Secure remote access without requiring a public IP address |
| **Zigbee coordinator** | Connection to wireless sensors                             |
| **Bluetooth**          | Connection to supported local sensors                      |
| **GPIO / I²C**         | Connection to vehicle and board-level sensors              |

More detailed architecture and hardware documentation will be added under [`docs/`](docs/).

---

## 🚀 Getting Started

CamperPilot is currently installed manually. A setup script for automated installation and configuration is planned.

### 1. Install openHABian

Install openHABian on a Raspberry Pi 4 using the official openHABian Raspberry Pi image.

After writing the image to an SD card:

1. Insert the SD card into the Raspberry Pi.
2. Connect the Raspberry Pi to the network.
3. Start the Raspberry Pi.
4. Wait for the initial openHABian installation to finish.
5. Connect to the system using SSH.
6. Open the openHABian configuration tool:

```bash
sudo openhabian-config
```

During the initial setup, configure at least:

* hostname
* user password
* system updates
* time zone
* network connection

A dedicated CamperPilot hostname such as the following is recommended:

```text
camperpilot
```

---

### 2. Configure openHAB

After the openHABian installation has completed, open the openHAB web interface:

```text
http://camperpilot:8080
```

Complete the initial openHAB setup and create the administrator account.

Bindings, Things, Items, Rules and dashboards are currently configured manually.

In a later project stage, the CamperPilot setup script will install the required openHAB configuration files automatically.

---

### 3. Configure Tailscale Remote Access

CamperPilot uses Tailscale for secure remote maintenance.

Tailscale allows access to the Raspberry Pi even when the camper's mobile router does not provide a public IPv4 address.

Tailscale can be installed through the openHABian configuration tool:

```bash
sudo openhabian-config
```

Select the Tailscale VPN setup option and connect the Raspberry Pi to the desired Tailscale network.

After installation, verify the connection:

```bash
tailscale status
```

The Raspberry Pi should then be reachable through its Tailscale IP address or its MagicDNS hostname.

No port forwarding or dynamic DNS configuration is required.

---

### 4. Install CamperPilot Configuration

The CamperPilot-specific installation is currently performed manually.

This includes:

* openHAB Things
* openHAB Items
* openHAB Rules
* transformations
* MQTT configuration
* system scripts
* systemd services
* required permissions and sudoers entries

The long-term goal is to provide a setup script such as:

```bash
sudo ./camperpilot-setup.sh
```

The script will eventually:

1. verify the operating system and Raspberry Pi model
2. install required packages
3. install openHAB configuration files
4. install CamperPilot system scripts
5. configure services and permissions
6. prepare MQTT and hardware integrations
7. validate the installation

The setup script is not yet available.

---

## 📊 Current Project Status

CamperPilot is under active development.

### Available or currently being integrated

* openHAB running on Raspberry Pi 4
* Zigbee sensor integration
* temperature and climate monitoring
* door and window monitoring
* presence and movement detection
* local openHAB dashboards
* MQTT broker
* Raspberry Pi system monitoring
* secure remote access using Tailscale

### Planned or under development

* automated installation script
* version-controlled openHAB configuration
* Bluetooth gas level sensor integration
* battery and current monitoring
* vehicle inclination measurement
* GPS and telemetry integration
* alarm and notification workflows
* local camper display
* custom CamperPilot hardware board

---

## 📁 Documentation

Detailed documentation will be maintained separately:

| Document                                         | Description                               |
| ------------------------------------------------ | ----------------------------------------- |
| [`docs/installation.md`](docs/installation.md)   | Complete installation instructions        |
| [`docs/remote-access.md`](docs/remote-access.md) | Tailscale setup and remote maintenance    |
| [`docs/hardware.md`](docs/hardware.md)           | Hardware components and wiring            |
| [`docs/openhab.md`](docs/openhab.md)             | openHAB bindings, Things, Items and Rules |
| [`docs/architecture.md`](docs/architecture.md)   | System architecture and design decisions  |

Some documents may still be under development.

---

## 🛣️ Roadmap

The project will be developed iteratively.

1. Document the current installation.
2. Add the existing openHAB configuration to the repository.
3. Collect and standardize required system scripts.
4. Define the target repository structure.
5. Create the first CamperPilot setup script.
6. Add installation validation and update mechanisms.
7. Expand hardware and sensor integrations.

---

## ⚠️ Disclaimer

CamperPilot is a private DIY and maker project.

It is not a certified:

* alarm system
* vehicle control system
* gas warning system
* fire detection system
* battery management system
* safety system

Any gas detection, intrusion detection, electrical monitoring or other safety-related functionality must be independently tested and validated before real-world use.

CamperPilot must not replace certified vehicle or safety equipment.

---

## 🤝 Contributing

Ideas, improvements and pull requests are welcome.

You may fork this repository and adapt the project to your own camper or motorhome. Hardware, wiring and vehicle-specific configurations may differ significantly.

Please document changes clearly and never assume that electrical configurations are transferable between different vehicles without validation.

---

## 📄 License

This project is licensed under the MIT License.
