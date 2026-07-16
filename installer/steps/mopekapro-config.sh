#!/usr/bin/env bash

readonly MOPEKAPRO_ADDRESS_PLACEHOLDER="__CAMPERPILOT_MOPEKAPRO_ADDRESS__"

read_mopekapro_choice() {
  local choice

  while true; do
    read -r -p "Will a Mopeka Pro gas level sensor be used? [y/N]: " choice

    case "${choice,,}" in
      y|yes) printf '1\n'; return ;;
      ""|n|no) printf '0\n'; return ;;
      *) log_warning "Invalid selection. Please enter y or n." ;;
    esac
  done
}

discover_mopekapro_address() {
  local address
  local device

  command -v bluetoothctl >/dev/null 2>&1 || return 1
  log_success "Scanning for a Mopeka Pro sensor for 15 seconds..." >&2
  bluetoothctl --timeout 15 scan on >/dev/null 2>&1 || true

  while IFS=' ' read -r _ device _; do
    [[ -n "${device:-}" ]] || continue
    if bluetoothctl info "${device}" 2>/dev/null | grep -Eqi 'ManufacturerData Key:[[:space:]]*0x0*59([[:space:]]|$)'; then
      address="$(normalize_bluetooth_address "${device}")"
      validate_bluetooth_address "Detected Mopeka Pro address" "${address}"
      printf '%s\n' "${address}"
      return 0
    fi
  done < <(bluetoothctl devices 2>/dev/null)

  return 1
}

read_mopekapro_address() {
  local address

  while true; do
    read -r -p "Mopeka Pro Bluetooth address (AA:BB:CC:DD:EE:FF): " address
    address="$(normalize_bluetooth_address "${address}")"
    if [[ "${address}" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
      printf '%s\n' "${address}"
      return
    fi
    log_warning "Invalid Bluetooth address. Use the format AA:BB:CC:DD:EE:FF."
  done
}

resolve_mopekapro_address() {
  local address

  address="${CAMPERPILOT_MOPEKAPRO_ADDRESS:-}"
  if [[ -z "${address}" ]]; then
    address="$(read_existing_thing_address "${TARGET_OPENHAB_CONFIG_DIR}/things/mopekapro.things" || true)"
  fi
  if [[ -z "${address}" ]]; then
    address="$(discover_mopekapro_address || true)"
  fi
  if [[ -z "${address}" ]]; then
    if [[ -t 0 ]]; then
      log_warning "No Mopeka Pro was detected automatically. Find its address with 'bluetoothctl scan on'."
      address="$(read_mopekapro_address)"
    else
      fail "No Mopeka Pro was detected. Set CAMPERPILOT_MOPEKAPRO_ADDRESS=AA:BB:CC:DD:EE:FF and rerun the installer."
    fi
  fi

  address="$(normalize_bluetooth_address "${address}")"
  validate_bluetooth_address CAMPERPILOT_MOPEKAPRO_ADDRESS "${address}"
  printf '%s\n' "${address}"
}

install_mopekapro_configuration() {
  local thing_source="${SOURCE_OPENHAB_CONFIG_DIR}/things/mopekapro.things"
  local thing_target="${TARGET_OPENHAB_CONFIG_DIR}/things/mopekapro.things"
  local item_source="${SOURCE_OPENHAB_CONFIG_DIR}/items/mopekapro.items"
  local item_target="${TARGET_OPENHAB_CONFIG_DIR}/items/mopekapro.items"
  local automation_source="${SOURCE_OPENHAB_CONFIG_DIR}/automation/js/mopekapro.js"
  local automation_target="${TARGET_OPENHAB_CONFIG_DIR}/automation/js/mopekapro.js"

  if [[ "${INSTALL_MOPEKAPRO:-0}" -ne 1 ]]; then
    log_success "Skipping optional Mopeka Pro configuration."
    return
  fi

  validate_source_file "${thing_source}"
  validate_source_file "${item_source}"
  validate_source_file "${automation_source}"

  log_success "Installing Mopeka Pro openHAB configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" \
    "${TARGET_OPENHAB_CONFIG_DIR}/things" \
    "${TARGET_OPENHAB_CONFIG_DIR}/items" \
    "${TARGET_OPENHAB_CONFIG_DIR}/automation/js"

  render_addressed_thing_file "${thing_source}" "${thing_target}" \
    "${MOPEKAPRO_ADDRESS_PLACEHOLDER}" "$(resolve_mopekapro_address)"
  install -o openhab -g openhab -m "${OPENHAB_CONFIG_FILE_MODE}" "${item_source}" "${item_target}"
  install -o openhab -g openhab -m "${OPENHAB_CONFIG_FILE_MODE}" "${automation_source}" "${automation_target}"

  verify_installed_file "${thing_target}" "664" "openhab:openhab"
  verify_installed_file "${item_target}" "664" "openhab:openhab"
  verify_installed_file "${automation_target}" "664" "openhab:openhab"
}

log_installed_mopekapro_configuration() {
  [[ "${INSTALL_MOPEKAPRO:-0}" -eq 1 ]] || return

  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/things/mopekapro.things"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/items/mopekapro.items"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/automation/js/mopekapro.js"
}

log_retained_mopekapro_configuration() {
  log_warning "  ${TARGET_OPENHAB_CONFIG_DIR}/things/mopekapro.things"
  log_warning "  ${TARGET_OPENHAB_CONFIG_DIR}/items/mopekapro.items"
  log_warning "  ${TARGET_OPENHAB_CONFIG_DIR}/automation/js/mopekapro.js"
}
