const { rules, triggers, items, actions } = require('openhab');

const CONFIG = Object.freeze({
  sensorGroup: 'Climate_TemperatureSensors',

  enabledItem: 'Climate_TemperatureAlarm_Enabled',
  thresholdItem: 'Climate_TemperatureAlarm_Threshold',
  triggeredItem: 'Climate_TemperatureAlarm_Triggered',
  detailsItem: 'Climate_TemperatureAlarm_Details',

  defaultThresholdCelsius: 35,
  hysteresisCelsius: 2,

  notificationTag: 'Temperaturalarm',
  notificationReferenceId: 'camper-temperature-alarm'
});

const SENSOR_LABELS = Object.freeze({
  // Temperature items and their display names can optionally be entered here,
  // for example: Dinette_ClimateSensor_Temperature: 'Dinette'
});


/**
 * Reads the state of a temperature item in degrees Celsius.
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
 * Returns all temperature sensors that can currently be evaluated.
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
 * Reads the configured threshold.
 *
 * @returns {number}
 */
function getThresholdCelsius() {
  const thresholdItem = items.getItem(CONFIG.thresholdItem);
  const threshold = getTemperatureCelsius(thresholdItem);

  if (threshold === null) {
    thresholdItem.postUpdate(`${CONFIG.defaultThresholdCelsius} °C`);
    return CONFIG.defaultThresholdCelsius;
  }

  return threshold;
}


/**
 * Creates a readable list of sensors.
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
 * Updates an item only if its state actually changes. This avoids unnecessary
 * events, persistence writes and UI updates on every sensor report.
 *
 * @param {object} item openHAB Item
 * @param {string} state new item state
 */
function postUpdateIfDifferent(item, state) {
  if (item.state !== state) {
    item.postUpdate(state);
  }
}


/**
 * Sends a broadcast push notification via openHAB Cloud.
 *
 * @param {string} title
 * @param {string} message
 */
function sendPushNotification(title, message) {
  actions.notificationBuilder(message)
    .withTitle(title)
    .withIcon('temperature')
    .withTag(CONFIG.notificationTag)
    .withReferenceId(CONFIG.notificationReferenceId)
    .send();
}


/**
 * Checks all sensors and activates or clears the alarm.
 *
 * @param {boolean} sendReminder
 */
function evaluateTemperatureAlarm(sendReminder = false) {
  const enabledItem = items.getItem(CONFIG.enabledItem);
  const activeItem = items.getItem(CONFIG.triggeredItem);
  const detailsItem = items.getItem(CONFIG.detailsItem);

  // Treat an Enabled item that has not yet been initialized as ON.
  const alarmEnabled = enabledItem.state !== 'OFF';
  const alarmActive = activeItem.state === 'ON';

  if (!alarmEnabled) {
    if (alarmActive) {
      activeItem.postUpdate('OFF');
      postUpdateIfDifferent(detailsItem, 'Temperaturalarm deaktiviert');

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
   * Trigger or update the alarm.
   */
  if (hotSensors.length > 0) {
    const sensorDetails = formatSensorList(hotSensors);

    postUpdateIfDifferent(detailsItem, sensorDetails);

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

  // Initialize the alarm state after the first successful check without an alarm.
  if (!alarmActive && activeItem.state !== 'OFF') {
    activeItem.postUpdate('OFF');
  }

  /*
   * Hysteresis:
   * The alarm is cleared only when all sensors are at least 2 °C below
   * the threshold.
   */
  const allSensorsBelowResetThreshold = sensors.every(
    sensor => sensor.temperature <= resetThreshold
  );

  if (alarmActive && allSensorsBelowResetThreshold) {
    const sensorDetails = formatSensorList(sensors);

    activeItem.postUpdate('OFF');
    postUpdateIfDifferent(
      detailsItem,
      `Temperatur wieder normal – ${sensorDetails}`
    );

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
 * Main rule:
 *
 * - Temperature sensor state change
 * - Threshold change
 * - Alarm activation or deactivation
 * - Completed openHAB startup
 */
rules.JSRule({
  name: 'Wohnmobil Temperaturalarm',
  description: 'Überwacht alle Temperatursensoren im Wohnmobil.',
  id: 'camper-temperature-alarm',
  tags: ['CamperPilot', 'Temperature', 'Alarm'],

  triggers: [
    // Zigbee sensors can report an unchanged value very frequently. Reacting
    // to every update needlessly executes the complete rule and can overwhelm
    // a Raspberry Pi when several sensors report at the same time.
    triggers.GroupStateChangeTrigger(
      CONFIG.sensorGroup
    ),

    triggers.ItemStateChangeTrigger(
      CONFIG.thresholdItem
    ),

    triggers.ItemStateChangeTrigger(
      CONFIG.enabledItem
    ),

    triggers.SystemStartlevelTrigger(100)
  ],

  execute: () => {
    evaluateTemperatureAlarm(false);
  }
});


/*
 * Reminder rule:
 *
 * Sends another notification every 30 minutes while the alarm is active.
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
    const triggeredItem = items.getItem(CONFIG.triggeredItem);

    if (triggeredItem.state === 'ON') {
      evaluateTemperatureAlarm(true);
    }
  }
});
