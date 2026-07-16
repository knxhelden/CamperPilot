#!/usr/bin/env bash

readonly BLUETOOTH_ADDRESS_PLACEHOLDER="__CAMPERPILOT_BLUETOOTH_ADDRESS__"
readonly OPENHAB_CONFIG_DIR_MODE="2775"
readonly OPENHAB_CONFIG_FILE_MODE="0664"

prepare_bluetooth_adapter() {
  log_success "Unblocking Bluetooth adapters..."
  rfkill unblock bluetooth

  log_success "Restarting the Bluetooth service..."
  systemctl restart bluetooth
}

configure_openhab_config_access() {
  if id -nG openhabian | tr ' ' '\n' | grep -qx openhab; then
    log_success "User openhabian is already a member of the openhab group."
  else
    log_success "Adding user openhabian to the openhab group..."
    usermod -a -G openhab openhabian
    log_warning "Log out and back in before editing openHAB configuration as openhabian."
  fi
}

install_openhab_config_services() {
  validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/services/addons.cfg"

  log_success "Installing openHAB services configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/services"

  install \
    -o openhab \
    -g openhab \
    -m "${OPENHAB_CONFIG_FILE_MODE}" \
    "${SOURCE_OPENHAB_CONFIG_DIR}/services/addons.cfg" \
    "${TARGET_OPENHAB_CONFIG_DIR}/services/addons.cfg"

  verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/services/addons.cfg" "664" "openhab:openhab"
}

normalize_bluetooth_address() {
  printf '%s\n' "${1^^}"
}

validate_bluetooth_address() {
  local name="$1"
  local address="$2"

  [[ "${address}" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]] \
    || fail "${name} must be a Bluetooth address such as AA:BB:CC:DD:EE:FF: ${address}"
}

read_existing_thing_address() {
  local target_file="$1"

  [[ -f "${target_file}" ]] || return 1
  sed -nE 's/.*\[address="(([[:xdigit:]]{2}:){5}[[:xdigit:]]{2})".*/\1/p' "${target_file}" | head -n 1
}

discover_bluetooth_adapter_address() {
  local address_file
  local -a address_files=(/sys/class/bluetooth/hci*/address)

  # Prefer hci0 for backwards compatibility, but do not assume that BlueZ
  # assigned that index. USB adapters and disabled onboard controllers can
  # cause the first usable controller to be named hci1 (or higher).
  if [[ -r /sys/class/bluetooth/hci0/address ]]; then
    cat /sys/class/bluetooth/hci0/address
    return
  fi

  for address_file in "${address_files[@]}"; do
    if [[ -r "${address_file}" ]]; then
      cat "${address_file}"
      return
    fi
  done

  # BlueZ may already know the controller while its sysfs address file is not
  # visible in the installer's environment (for example in a container).
  if command -v bluetoothctl >/dev/null 2>&1; then
    bluetoothctl list 2>/dev/null \
      | sed -nE 's/^Controller[[:space:]]+(([[:xdigit:]]{2}:){5}[[:xdigit:]]{2})([[:space:]].*)?$/\1/p' \
      | head -n 1
  fi
}

resolve_bluetooth_adapter_address() {
  local address

  address="${CAMPERPILOT_BLUETOOTH_ADDRESS:-}"
  if [[ -z "${address}" ]]; then
    address="$(read_existing_thing_address "${TARGET_OPENHAB_CONFIG_DIR}/things/bluetooth.things" || true)"
  fi
  if [[ -z "${address}" ]]; then
    address="$(discover_bluetooth_adapter_address || true)"
  fi
  [[ -n "${address}" ]] \
    || fail "No Bluetooth adapter was found. Check 'bluetoothctl list' or set CAMPERPILOT_BLUETOOTH_ADDRESS=AA:BB:CC:DD:EE:FF and rerun the installer."

  address="$(normalize_bluetooth_address "${address}")"
  validate_bluetooth_address CAMPERPILOT_BLUETOOTH_ADDRESS "${address}"
  printf '%s\n' "${address}"
}

render_addressed_thing_file() {
  local source_file="$1"
  local target_file="$2"
  local placeholder="$3"
  local address="$4"

  sed "s|${placeholder}|${address}|g" "${source_file}" \
    | install -o openhab -g openhab -m "${OPENHAB_CONFIG_FILE_MODE}" /dev/stdin "${target_file}"
}

install_openhab_thing_file() {
  local thing_file="$1"
  local source_file="${SOURCE_OPENHAB_CONFIG_DIR}/things/${thing_file}"
  local target_file="${TARGET_OPENHAB_CONFIG_DIR}/things/${thing_file}"

  if [[ "${thing_file}" == "bluetooth.things" ]]; then
    render_addressed_thing_file "${source_file}" "${target_file}" "${BLUETOOTH_ADDRESS_PLACEHOLDER}" "$(resolve_bluetooth_adapter_address)"
    return
  fi

  install \
    -o openhab \
    -g openhab \
    -m "${OPENHAB_CONFIG_FILE_MODE}" \
    "${source_file}" \
    "${target_file}"
}

install_openhab_config_things() {
  local thing_file
  local thing_files=(
    "systeminfo.things"
    "bluetooth.things"
  )

  for thing_file in "${thing_files[@]}"; do
    validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/things/${thing_file}"
  done

  log_success "Installing openHAB things configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/things"

  for thing_file in "${thing_files[@]}"; do
    install_openhab_thing_file "${thing_file}"
  done

  for thing_file in "${thing_files[@]}"; do
    verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/things/${thing_file}" "664" "openhab:openhab"
  done
}

install_openhab_config_items() {
  local item_file
  local item_files=(
    "climate.items"
    "resources.items"
    "security.items"
    "structure.items"
    "system.items"
  )

  for item_file in "${item_files[@]}"; do
    validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/items/${item_file}"
  done

  log_success "Installing openHAB items configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/items"

  for item_file in "${item_files[@]}"; do
    install \
      -o openhab \
      -g openhab \
      -m "${OPENHAB_CONFIG_FILE_MODE}" \
      "${SOURCE_OPENHAB_CONFIG_DIR}/items/${item_file}" \
      "${TARGET_OPENHAB_CONFIG_DIR}/items/${item_file}"
  done

  for item_file in "${item_files[@]}"; do
    verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/items/${item_file}" "664" "openhab:openhab"
  done
}

install_openhab_config_persistence() {
  validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/persistence/mapdb.persist"

  log_success "Installing openHAB persistence configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/persistence"

  install \
    -o openhab \
    -g openhab \
    -m "${OPENHAB_CONFIG_FILE_MODE}" \
    "${SOURCE_OPENHAB_CONFIG_DIR}/persistence/mapdb.persist" \
    "${TARGET_OPENHAB_CONFIG_DIR}/persistence/mapdb.persist"

  verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/persistence/mapdb.persist" "664" "openhab:openhab"
}

install_openhab_config_automation() {
  local automation_file
  local automation_files=(
    "camperpilot_system.js"
    "temperature_alarm.js"
  )

  for automation_file in "${automation_files[@]}"; do
    validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/automation/js/${automation_file}"
  done

  log_success "Installing openHAB automation configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/automation"
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/automation/js"

  for automation_file in "${automation_files[@]}"; do
    install \
      -o openhab \
      -g openhab \
      -m "${OPENHAB_CONFIG_FILE_MODE}" \
      "${SOURCE_OPENHAB_CONFIG_DIR}/automation/js/${automation_file}" \
      "${TARGET_OPENHAB_CONFIG_DIR}/automation/js/${automation_file}"
  done

  for automation_file in "${automation_files[@]}"; do
    verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/automation/js/${automation_file}" "664" "openhab:openhab"
  done
}

install_openhab_config_sitemaps() {
  local sitemap_file
  local sitemap_files=(
    "camperpilot.sitemap"
  )

  for sitemap_file in "${sitemap_files[@]}"; do
    validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/sitemaps/${sitemap_file}"
  done

  log_success "Installing openHAB sitemaps configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/sitemaps"

  for sitemap_file in "${sitemap_files[@]}"; do
    install \
      -o openhab \
      -g openhab \
      -m "${OPENHAB_CONFIG_FILE_MODE}" \
      "${SOURCE_OPENHAB_CONFIG_DIR}/sitemaps/${sitemap_file}" \
      "${TARGET_OPENHAB_CONFIG_DIR}/sitemaps/${sitemap_file}"
  done

  for sitemap_file in "${sitemap_files[@]}"; do
    verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/sitemaps/${sitemap_file}" "664" "openhab:openhab"
  done
}

install_openhab_configuration() {
  prepare_bluetooth_adapter
  configure_openhab_config_access
  install_openhab_config_services
  install_openhab_config_sitemaps
  install_openhab_config_things
  install_openhab_config_items
  install_openhab_config_persistence
  install_openhab_config_automation
}
