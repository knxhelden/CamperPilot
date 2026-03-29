# 🚐 Camper Pilot

> A Raspberry Pi–powered smart monitoring and automation platform for camper vans and motorhomes.

![Status](https://img.shields.io/badge/Project-DIY%20Prototype-2ea44f)
![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi%204-c51a4a)
![Automation](https://img.shields.io/badge/Automation-openHAB-ff8c00)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## ✨ Overview

**Camper Pilot** helps turn a camper into a connected, monitorable, and safer living space.

It combines:
- 🧠 **Local automation** (openHAB)
- 📡 **Sensor connectivity** (Zigbee + MQTT)
- 🛰️ **Tracking and telemetry** (GNSS + LTE)
- 🔋 **Utility monitoring** (power and environment)

---

## 🧰 Hardware

### GPIO-connected components

| Component | Purpose |
|---|---|
| **INA219** | Early-stage voltage/current measurement |
| **MPU6050** | Inclination sensing for leveling support |

### Wiring (Raspberry Pi GPIO)

#### INA219

- VCC → 3.3V
- GND → GND
- SDA → GPIO2 / Pin 3
- SCL → GPIO3 / Pin 5

#### MPU6050

- VCC → 3.3V
- GND → GND
- SDA → GPIO2 / Pin 3
- SCL → GPIO3 / Pin 5

### Other components

| Component | Purpose |
|---|---|
| **Raspberry Pi 4** | Main platform and automation host |
| **SONOFF Zigbee 3.0 USB-Dongle Plus (ZBDongle-P)** | Zigbee coordinator |
| **SONOFF Zigbee contact & climate sensors** | Door/window state + indoor conditions |
| **Waveshare Cat-1 / GNSS HAT** | LTE connectivity + GPS position |
| **DROK DC-DC Buck Converter (12V/24V → 5V)** | Power supply step-down converter for system voltage |

Power converter used:
- https://www.amazon.de/dp/B09B833LJ4?ref=ppx_yo2ov_dt_b_fed_asin_title&th=1

---

## 💻 Software Stack

- 🏠 **openHAB** — central automation system
- 📨 **Mosquitto** — MQTT message broker

---

## 🗺️ Planned Use Cases

The platform is designed for practical camper scenarios:

- 🚪 Check whether doors or windows are open
- 🌡️ Monitor indoor climate while parked
- 🚨 Trigger intrusion-related alerts
- 📍 Determine current GPS location
- 🖥️ Display local system status on an in-camper screen
- 📲 Receive remote notifications over LTE
- 🔋 Observe battery and utility values
- ⚖️ Support vehicle leveling on ramps

---

## ⚠️ Disclaimer

This is a **private DIY / maker project** for smart monitoring and automation in camper vehicles.

It is **not** a certified safety, security, or alarm system.

> Any gas detection, alarming, or other safety-critical functionality must be validated thoroughly before real-world deployment.

---

## 🤝 Contributing

Contributions are welcome:
- 💡 Ideas
- 🛠️ Improvements
- 🔀 Pull requests

If you build something similar, feel free to fork this repository, adapt it to your own vehicle, and improve the docs.
