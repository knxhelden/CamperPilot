#!/usr/bin/env bash

readonly ZIGBEE_PORT_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_PORT__"

install_openhab_config_services() {
  validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/services/addons.cfg"

  log_success "Installing openHAB services configuration..."
  install -d -o openhab -g openhab -m 0755 "${TARGET_OPENHAB_CONFIG_DIR}/services"

  install \
    -o openhab \
    -g openhab \
    -m 0644 \
    "${SOURCE_OPENHAB_CONFIG_DIR}/services/addons.cfg" \
    "${TARGET_OPENHAB_CONFIG_DIR}/services/addons.cfg"

  verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/services/addons.cfg" "644" "openhab:openhab"
}

resolve_zigbee_port() {
  local serial_device
  local serial_devices=()

  if [[ -n "${CAMPERPILOT_ZIGBEE_PORT:-}" ]]; then
    [[ -e "${CAMPERPILOT_ZIGBEE_PORT}" ]] \
      || fail "Configured Zigbee port does not exist: ${CAMPERPILOT_ZIGBEE_PORT}"

    printf '%s\n' "${CAMPERPILOT_ZIGBEE_PORT}"
    return
  fi

  if [[ -d /dev/serial/by-id ]]; then
    while IFS= read -r -d '' serial_device; do
      serial_devices+=("${serial_device}")
    done < <(find /dev/serial/by-id -maxdepth 1 -type l -print0 | sort -z)
  fi

  case "${#serial_devices[@]}" in
    0)
      fail "No Zigbee serial device found in /dev/serial/by-id. Set CAMPERPILOT_ZIGBEE_PORT=/dev/serial/by-id/<device> and rerun the installer."
      ;;
    1)
      printf '%s\n' "${serial_devices[0]}"
      ;;
    *)
      log_error "Multiple serial devices found in /dev/serial/by-id."
      for serial_device in "${serial_devices[@]}"; do
        log_error "  ${serial_device}"
      done
      fail "Set CAMPERPILOT_ZIGBEE_PORT=/dev/serial/by-id/<device> and rerun the installer."
      ;;
  esac
}

install_openhab_thing_file() {
  local thing_file="$1"
  local source_file="${SOURCE_OPENHAB_CONFIG_DIR}/things/${thing_file}"
  local target_file="${TARGET_OPENHAB_CONFIG_DIR}/things/${thing_file}"
  local zigbee_port

  if grep -q "${ZIGBEE_PORT_PLACEHOLDER}" "${source_file}"; then
    zigbee_port="$(resolve_zigbee_port)"
    sed "s|${ZIGBEE_PORT_PLACEHOLDER}|${zigbee_port}|g" "${source_file}" \
      | install -o openhab -g openhab -m 0644 /dev/stdin "${target_file}"
    log_success "Installed ${thing_file} with Zigbee port ${zigbee_port}"
    return
  fi

  install \
    -o openhab \
    -g openhab \
    -m 0644 \
    "${source_file}" \
    "${target_file}"
}

install_openhab_config_things() {
  local thing_file
  local thing_files=(
    "systeminfo.things"
    "zigbee.things"
  )

  for thing_file in "${thing_files[@]}"; do
    validate_source_file "${SOURCE_OPENHAB_CONFIG_DIR}/things/${thing_file}"
  done

  log_success "Installing openHAB things configuration..."
  install -d -o openhab -g openhab -m 0755 "${TARGET_OPENHAB_CONFIG_DIR}/things"

  for thing_file in "${thing_files[@]}"; do
    install_openhab_thing_file "${thing_file}"
  done

  for thing_file in "${thing_files[@]}"; do
    verify_installed_file "${TARGET_OPENHAB_CONFIG_DIR}/things/${thing_file}" "644" "openhab:openhab"
  done
}

install_openhab_config_items() {
  log_success "Installing openHAB items configuration..."
}

install_openhab_config_automation() {
  log_success "Installing openHAB automation configuration..."
}

install_openhab_config_sitemaps() {
  log_success "Installing openHAB sitemaps configuration..."
}

install_openhab_configuration() {
  install_openhab_config_services
  install_openhab_config_things
  install_openhab_config_items
  install_openhab_config_automation
  install_openhab_config_sitemaps
}
