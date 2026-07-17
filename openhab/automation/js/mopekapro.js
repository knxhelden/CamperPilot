const CONFIG = Object.freeze({
  tankUsableHeightItem: "Mopekapro_TankUsableHeight",
  defaultTankUsableHeightMillimeters: 400
});

rules.JSRule({
  name: "Mopeka BLE Rohdaten dekodieren",
  description: "Dekodiert Manufacturer Raw Data des Mopeka Pro Sensors",
  triggers: [
    triggers.ItemStateChangeTrigger("Mopekapro_ManufacturerRaw")
  ],
  execute: (event) => {
    const rawState = event.newState.toString();

    if (!rawState || rawState === "NULL" || rawState === "UNDEF") {
      return;
    }

    const hex = rawState.replace(/^0x/i, "").trim();

    if (hex.length < 24) {
      console.warn(`Mopeka: Rohdaten zu kurz: ${hex}`);
      return;
    }

    const bytes = [];
    for (let i = 0; i < hex.length; i += 2) {
      bytes.push(parseInt(hex.substring(i, i + 2), 16));
    }

    if (bytes[0] !== 0x59 || bytes[1] !== 0x00) {
      console.warn(`Mopeka: Manufacturer ID passt nicht: ${hex}`);
      return;
    }

    const hardwareId = bytes[2] & 0x7F;

    const batteryRaw = bytes[3] & 0x7F;
    const batteryVoltage = batteryRaw / 32.0;

    let batteryPercent = ((batteryVoltage - 2.2) / 0.65) * 100.0;
    batteryPercent = Math.max(0, Math.min(100, batteryPercent));

    const tempRaw = bytes[4] & 0x7F;
    const temperatureC = tempRaw - 40;

    const rawCombined = (bytes[6] << 8) + bytes[5];
    const quality = (rawCombined >> 14) & 0x03;
    const rawLevel = rawCombined & 0x3FFF;

    const sensorId = [
      bytes[7].toString(16).padStart(2, "0"),
      bytes[8].toString(16).padStart(2, "0"),
      bytes[9].toString(16).padStart(2, "0")
    ].join(":").toUpperCase();

    // Mopeka LPG/Propane compensation coefficients
    const c0 = 0.573045;
    const c1 = -0.002822;
    const c2 = -0.00000535;

    const fluidHeightMm = rawLevel * (c0 + c1 * tempRaw + c2 * tempRaw * tempRaw);

    let tankUsableHeightMm = CONFIG.defaultTankUsableHeightMillimeters;
    const tankHeightItem = items.getItem(CONFIG.tankUsableHeightItem);

    if (
      tankHeightItem &&
      tankHeightItem.state &&
      tankHeightItem.state.toString() !== "NULL" &&
      tankHeightItem.state.toString() !== "UNDEF"
    ) {
      const stateString = tankHeightItem.state.toString().trim();

      if (stateString.endsWith("mm")) {
        tankUsableHeightMm = parseFloat(stateString.replace("mm", "").trim());
      } else if (stateString.endsWith("cm")) {
        tankUsableHeightMm = parseFloat(stateString.replace("cm", "").trim()) * 10;
      } else if (stateString.endsWith("m")) {
        tankUsableHeightMm = parseFloat(stateString.replace("m", "").trim()) * 1000;
      } else {
        tankUsableHeightMm = parseFloat(stateString);
      }
    }

    if (isNaN(tankUsableHeightMm) || tankUsableHeightMm <= 0) {
      console.warn(
        `Mopeka: Ungültige Tankhöhe '${tankHeightItem.state}', verwende ${CONFIG.defaultTankUsableHeightMillimeters} mm`
      );
      tankUsableHeightMm = CONFIG.defaultTankUsableHeightMillimeters;
    }

    if (
      !tankHeightItem.state ||
      tankHeightItem.state.toString() === "NULL" ||
      tankHeightItem.state.toString() === "UNDEF" ||
      isNaN(parseFloat(tankHeightItem.state.toString())) ||
      parseFloat(tankHeightItem.state.toString()) <= 0
    ) {
      tankHeightItem.postUpdate(`${CONFIG.defaultTankUsableHeightMillimeters} mm`);
    }

    let levelPercent = (fluidHeightMm / tankUsableHeightMm) * 100.0;
    levelPercent = Math.max(0, Math.min(100, levelPercent));

    items.getItem("Mopekapro_BatteryVoltage").postUpdate(batteryVoltage.toFixed(2));
    items.getItem("Mopekapro_BatteryLevel").postUpdate(`${Math.round(batteryPercent)} %`);
    items.getItem("Mopekapro_Temperature").postUpdate(`${temperatureC} °C`);
    items.getItem("Mopekapro_RawLevel").postUpdate(rawLevel);
    items.getItem("Mopekapro_Quality").postUpdate(quality);
    items.getItem("Mopekapro_FluidHeight").postUpdate(`${fluidHeightMm.toFixed(0)} mm`);
    items.getItem("Mopekapro_Level").postUpdate(`${Math.round(levelPercent)} %`);
    items.getItem("Mopekapro_SensorId").postUpdate(sensorId);

    console.info(
      `Mopeka decoded: hw=${hardwareId}, battery=${batteryVoltage.toFixed(2)}V/${batteryPercent.toFixed(0)}%, temp=${temperatureC}°C, rawLevel=${rawLevel}, quality=${quality}/3, height=${fluidHeightMm.toFixed(0)}mm, tankHeight=${tankUsableHeightMm.toFixed(0)}mm, level=${levelPercent.toFixed(0)}%, sensorId=${sensorId}`
    );
  }
});
