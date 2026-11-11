# CamperPilot Architecture

CamperPilot consists of a central Core and distributed wireless Nodes.

## Core

- Raspberry Pi running openHAB.
- Central configuration, automation and visualization.
- BLE communication with Nodes.
- Existing Zigbee sensors connected through the Zigbee coordinator.

## Core Hardware

| Component | Function |
| --------- | -------- |
| Raspberry Pi 4 | Central controller running openHAB; integrated BLE for Node communication |
| GY-521 / MPU6050 | Motion and vehicle tilt sensing |
| AM2301 connector | 	Connection for a temperature and humidity sensor |
| 12 V siren output | Controls an external alarm siren |
| 12 V alarm light output | Controls an external alarm light |
| INA226 with external shunt | Measures leisure battery voltage and current |
| XL4015 | Steps down battery voltage to 5 V for the Raspberry Pi |
| Sonoff ZBDongle-E | Zigbee connectivity for external sensors |
| Push button | Local operation; function to be defined |
| 3 status LEDs | Power, ready and fault indication |
| Protection circuitry and fuses | Protects the power supply and outputs |

## Nodes

Each Node runs its own firmware and handles its inputs and outputs locally.

| Node | Function |
| ---- | -------- |
| Bus Connector | Read and decode vehicle and system bus data |
| Relay | Switch loads and process local buttons |
| LED | Control brightness and color through local PWM |

## Node Hardware

- Preferred microcontroller: Nordic nRF54L15.
- Candidate PCB module: EBYTE E73-2G4M54LP(15) with integrated antenna.
- Programming/debugging through SWD (Serial Wire Debug).
- Local power regulation and protection circuitry.
- Dedicated circuitry for relays, LEDs or sensors.

## Communication

- Bluetooth Low Energy (BLE).
- Direct Core-to-Node connections; initially no mesh.

## Operating Requirements

- Low power consumption, including radio, voltage regulators and output circuitry.
- Local button operation independent of Core availability.
- Defined behavior on communication loss and restart.
- Range, response time and power consumption require prototype validation.

## Links

- KFZ-Sicherungshalter: https://www.reichelt.de/de/de/shop/produkt/kfz-sicherungshalter_minioto_30_a_125_v_printmontage-229120
- Spannungswandler XL4015: https://www.az-delivery.de/products/spannungswandler-5a-8-36v-zu-1-25-32v