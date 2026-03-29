# 🚐 Camper Pilot

> A Raspberry Pi–powered smart monitoring and automation platform for camper vans and motorhomes.

![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi%204-C51A4A?logo=raspberrypi&logoColor=white)
![Automation](https://img.shields.io/badge/Automation-openHAB-FA6E0A)
![Messaging](https://img.shields.io/badge/MQTT-Mosquitto-3C5280)
![Connectivity](https://img.shields.io/badge/Connectivity-LTE%20%2B%20GNSS-0E9F6E)
![Status](https://img.shields.io/badge/Project-DIY%20%7C%20WIP-6B7280)

---

## ✨ Project Vision

**Camper Pilot** aims to bring smart-home comfort and operational awareness into a mobile camper setup.

The idea is simple: combine affordable hardware, robust messaging, and automation rules to keep an eye on your vehicle's status—whether you are parked nearby or away from your camper.

---

## 🧩 Hardware Stack

- 🧠 **Raspberry Pi 4** as the central platform
- 📡 **SONOFF Zigbee 3.0 USB-Dongle Plus (ZBDongle-P)** for Zigbee networking
- 🚪 **SONOFF Zigbee contact & climate sensors** for cabin monitoring
- 🌍 **Waveshare Cat-1 / GNSS HAT** for LTE connectivity and GPS tracking
- 🔋 **INA219** for early battery voltage/current measurement experiments
- ⚖️ **MPU6050** for inclination and leveling support

---

## 🖥️ Software Stack

- 🏠 **openHAB** as the automation system
- 📨 **Mosquitto** as the MQTT broker

---

## 🎯 Planned Use Cases

This project is designed around practical camper-life scenarios:

- ✅ Check whether **doors or windows** are open
- 🌡️ Monitor **indoor climate** while the vehicle is parked
- 🚨 Trigger alarm notifications when **intrusion** is detected
- 📍 Determine the vehicle's **current GPS position**
- 🖼️ View system status locally on an **in-cabin display**
- 📲 Receive **remote notifications** via LTE connectivity
- 🔌 Monitor **battery values** and additional utilities
- 📐 Level the vehicle on ramps using **tilt measurements**

---

## ⚠️ Disclaimer

This is a private **DIY / maker project** for smart camper monitoring and automation.
It is **not** a certified security or safety system.

Any gas detection, alarm, or other safety-relevant integrations must be validated carefully before real-world operation.

---

## 🤝 Contributing

Ideas, improvements, and pull requests are welcome.

If you are building something similar, feel free to fork this repository, adapt the setup to your vehicle, and improve the documentation along the way.
