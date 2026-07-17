rules.JSRule({
  name: 'CamperPilot - Shutdown',
  description: 'Fährt openHABian sauber herunter, wenn das Shutdown-Item geschaltet wird.',
  triggers: [
    triggers.ItemCommandTrigger('System_CamperPilot_Shutdown', 'ON')
  ],
  execute: (event) => {
    console.warn('Shutdown wurde über openHAB angefordert');

    items.getItem('System_CamperPilot_Shutdown').postUpdate('OFF');

    actions.Exec.executeCommandLine(
      '/usr/bin/sudo',
      '/usr/local/sbin/camperpilot-poweroff'
    );
  }
});


rules.JSRule({
  name: 'CamperPilot - Reboot',
  description: 'Startet openhabian neu, wenn das Reboot-Item geschaltet wird.',
  triggers: [
    triggers.ItemCommandTrigger('System_CamperPilot_Reboot', 'ON')
  ],
  execute: (event) => {
    console.warn('Reboot wurde über openHAB angefordert');

    items.getItem('System_CamperPilot_Reboot').postUpdate('OFF');

    actions.Exec.executeCommandLine(
      '/usr/bin/sudo',
      '/usr/local/sbin/camperpilot-reboot'
    );
  }
});