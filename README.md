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

## 🚀 Installation

Start with the openHABian base installation:

* [Install CamperPilot](docs/installation.md)
* [Configure remote access with Tailscale](docs/remote-access.md)

CamperPilot-specific configuration and the automated setup script are still under development.

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

| Document                                         | Description                               |
| ------------------------------------------------ | ----------------------------------------- |
| [`docs/installation.md`](docs/installation.md)   | Base system installation                  |
| [`docs/remote-access.md`](docs/remote-access.md) | Secure remote access using Tailscale      |
| [`docs/hardware.md`](docs/hardware.md)           | Hardware components and wiring            |
| [`docs/openhab.md`](docs/openhab.md)             | openHAB bindings, Things, Items and rules |
| [`docs/architecture.md`](docs/architecture.md)   | System architecture and design decisions  |

Some documents are still under development.

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
