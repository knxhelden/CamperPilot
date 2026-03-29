# Camper Pilot

A Raspberry Pi based smart home and monitoring platform for camper vans and motorhomes.

## Hardware

- Raspberry Pi 4 as core platform
- SONOFF ZBDongle-E for Zigbee
- SONOFF Zigbee contact and climate sensors
- Waveshare Cat-1 / GNSS HAT for connectivity and tracking
- INA219 for initial voltage/current measurement experiments
- MPU6050 for inclination / leveling support

## Software

- openHAB as automation system
- Mosquitto as MQTT Broker

## Planned Use Cases

This project is intended to support the following real-world camper scenarios:

- Check whether doors or windows are open
- Monitor indoor climate while the vehicle is parked
- Trigger alarm notifications when intrusion is detected
- Determine the current GPS position of the vehicle
- View system status locally on a screen inside the camper
- Receive remote notifications through LTE connectivity
- Monitor battery-related values and other utilities
- Align the vehicle on ramps until it is level

## Disclaimer

This project is a private DIY / maker project for smart monitoring and automation inside a camper vehicle. It is not a certified security or safety system.

Any integration related to gas detection, alarming, or safety-relevant monitoring must be validated carefully before real-world use.

## Contributing

Ideas, improvements, and pull requests are welcome.

If you build something similar, feel free to fork the repository, adapt the setup to your own vehicle, and improve the documentation.