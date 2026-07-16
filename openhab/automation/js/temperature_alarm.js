const { rules, triggers, items, actions } = require('openhab');

const CONFIG = Object.freeze({
  sensorGroup: 'Climate_TemperatureSensors',

  enabledItem: 'Climate_HighTemperatureAlarm_Enabled',
  thresholdItem: 'Climate_HighTemperatureAlarm_Threshold',
  triggeredItem: 'Climate_HighTemperatureAlarm_Triggered',
  detailsItem: 'Climate_HighTemperatureAlarm_Details',

  defaultThresholdCelsius: 35,
  hysteresisCelsius: 2,

  notificationTag: 'Temperaturalarm',
  notificationReferenceId: 'camper-temperature-alarm'
});

const SENSOR_LABELS = Object.freeze({
  Dinette_ClimateSensor_Temperature: 'Dinette',
  Sleeping_ClimateSensor_Temperature: 'Schlafen',
  Garage_ClimateSensor_Temperature: 'Garage'
});


/**
 * Liest den Zustand eines Temperatur-Items in Grad Celsius.
 *
 * @param {object} item openHAB Item
 * @returns {number|null}
 */
function getTemperatureCelsius(item) {
  const quantity = item.quantityState;

  if (quantity === null) {
    return null;
  }

  const celsius = quantity.toUnit('°C');

  if (celsius === null) {
    return null;
  }

  return celsius.float;
}


/**
 * Liefert alle aktuell auswertbaren Temperatursensoren.
 *
 * @returns {Array<{name: string, label: string, temperature: number}>}
 */
function getSensorTemperatures() {
  const sensorGroup = items.getItem(CONFIG.sensorGroup);

  return sensorGroup.members
    .map(sensorItem => {
      const temperature = getTemperatureCelsius(sensorItem);

      if (temperature === null) {
        console.warn(
          `Temperaturalarm: Sensor ${sensorItem.name} hat keinen gültigen Temperaturwert: ${sensorItem.state}`
        );

        return null;
      }

      return {
        name: sensorItem.name,
        label: SENSOR_LABELS[sensorItem.name] ?? sensorItem.label ?? sensorItem.name,
        temperature: temperature
      };
    })
    .filter(sensor => sensor !== null);
}


/**
 * Liest den konfigurierten Grenzwert.
 *
 * @returns {number}
 */
function getThresholdCelsius() {
  const thresholdItem = items.getItem(CONFIG.thresholdItem);
  const threshold = getTemperatureCelsius(thresholdItem);

  return threshold ?? CONFIG.defaultThresholdCelsius;
}


/**
 * Erzeugt eine lesbare Liste der Sensoren.
 *
 * @param {Array<{label: string, temperature: number}>} sensors
 * @returns {string}
 */
function formatSensorList(sensors) {
  return sensors
    .map(sensor => `${sensor.label}: ${sensor.temperature.toFixed(1)} °C`)
    .join(', ');
}


/**
 * Sendet eine Broadcast-Push-Benachrichtigung über openHAB Cloud.
 *
 * @param {string} title
 * @param {string} message
 */
function sendPushNotification(title, message) {
  actions.notificationBuilder(message)
    .withTitle(title)
    .withIcon('energy')
    .withTag(CONFIG.notificationTag)
    .withReferenceId(CONFIG.notificationReferenceId)
    .send();
}


/**
 * Prüft alle Sensoren und setzt beziehungsweise beendet den Alarm.
 *
 * @param {boolean} sendReminder
 */
function evaluateTemperatureAlarm(sendReminder = false) {
  const enabledItem = items.getItem(CONFIG.enabledItem);
  const activeItem = items.getItem(CONFIG.triggeredItem);
  const detailsItem = items.getItem(CONFIG.detailsItem);

  // Ein noch nicht initialisiertes Enabled-Item wird wie ON behandelt.
  const alarmEnabled = enabledItem.state !== 'OFF';
  const alarmActive = activeItem.state === 'ON';

  if (!alarmEnabled) {
    if (alarmActive) {
      activeItem.postUpdate('OFF');
      detailsItem.postUpdate('Temperaturalarm deaktiviert');

      actions.NotificationAction
        .hideBroadcastNotificationByReferenceId(
          CONFIG.notificationReferenceId
        );
    }

    return;
  }

  const threshold = getThresholdCelsius();
  const resetThreshold = threshold - CONFIG.hysteresisCelsius;
  const sensors = getSensorTemperatures();

  if (sensors.length === 0) {
    console.warn(
      'Temperaturalarm: Es steht aktuell kein gültiger Temperatursensor zur Verfügung.'
    );

    return;
  }

  const hotSensors = sensors.filter(
    sensor => sensor.temperature >= threshold
  );

  /*
   * Alarm auslösen beziehungsweise aktualisieren.
   */
  if (hotSensors.length > 0) {
    const sensorDetails = formatSensorList(hotSensors);

    detailsItem.postUpdate(sensorDetails);

    if (!alarmActive) {
      activeItem.postUpdate('ON');

      const message =
        `Im Wohnmobil wurde eine zu hohe Temperatur gemessen. ` +
        `${sensorDetails}. ` +
        `Alarmgrenze: ${threshold.toFixed(1)} °C.`;

      console.warn(`Temperaturalarm ausgelöst: ${message}`);

      sendPushNotification(
        'Temperaturalarm Wohnmobil',
        message
      );
    } else if (sendReminder) {
      const message =
        `Der Temperaturalarm ist weiterhin aktiv. ` +
        `${sensorDetails}. ` +
        `Alarmgrenze: ${threshold.toFixed(1)} °C.`;

      console.warn(`Temperaturalarm weiterhin aktiv: ${message}`);

      sendPushNotification(
        'Temperaturalarm weiterhin aktiv',
        message
      );
    }

    return;
  }

  /*
   * Hysterese:
   * Der Alarm wird erst zurückgesetzt, wenn alle Sensoren mindestens
   * 2 °C unterhalb des Grenzwerts liegen.
   */
  const allSensorsBelowResetThreshold = sensors.every(
    sensor => sensor.temperature <= resetThreshold
  );

  if (alarmActive && allSensorsBelowResetThreshold) {
    const sensorDetails = formatSensorList(sensors);

    activeItem.postUpdate('OFF');
    detailsItem.postUpdate(`Temperatur wieder normal – ${sensorDetails}`);

    const message =
      `Die Temperaturen im Wohnmobil sind wieder unter ` +
      `${resetThreshold.toFixed(1)} °C gefallen. ` +
      `${sensorDetails}.`;

    console.info(`Temperaturalarm beendet: ${message}`);

    sendPushNotification(
      'Temperaturalarm beendet',
      message
    );
  }
}


/*
 * Hauptregel:
 *
 * - Aktualisierung eines Temperatursensors
 * - Änderung des Grenzwerts
 * - Aktivierung oder Deaktivierung des Alarms
 * - vollständiger openHAB-Start
 */
rules.JSRule({
  name: 'Wohnmobil Temperaturalarm',
  description: 'Überwacht alle Temperatursensoren im Wohnmobil.',
  id: 'camper-temperature-alarm',
  tags: ['CamperPilot', 'Temperature', 'Alarm'],

  triggers: [
    triggers.GroupStateUpdateTrigger(
      CONFIG.sensorGroup
    ),

    triggers.ItemStateUpdateTrigger(
      CONFIG.thresholdItem
    ),

    triggers.ItemStateUpdateTrigger(
      CONFIG.enabledItem
    ),

    triggers.SystemStartlevelTrigger(100)
  ],

  execute: () => {
    evaluateTemperatureAlarm(false);
  }
});


/*
 * Erinnerungsregel:
 *
 * Solange der Alarm aktiv ist, wird alle 30 Minuten erneut informiert.
 */
rules.JSRule({
  name: 'Wohnmobil Temperaturalarm Erinnerung',
  description: 'Erinnert alle 30 Minuten an einen aktiven Temperaturalarm.',
  id: 'camper-temperature-alarm-reminder',
  tags: ['CamperPilot', 'Temperature', 'Alarm'],

  triggers: [
    triggers.GenericCronTrigger('0 0/30 * * * ?')
  ],

  execute: () => {
    evaluateTemperatureAlarm(true);
  }
});