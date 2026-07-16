#!/usr/bin/env bash

readonly ZIGBEE_PORT_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_PORT__"
readonly ZIGBEE_PAN_ID_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_PAN_ID__"
readonly ZIGBEE_EXTENDED_PAN_ID_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID__"
readonly ZIGBEE_NETWORK_KEY_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_NETWORK_KEY__"

read_zigbee_choice() {
  local choice

  while true; do
    read -r -p "Will Zigbee be used with CamperPilot? [y/N]: " choice
    case "${choice,,}" in
      y|yes) printf '1\n'; return ;;
      ""|n|no) printf '0\n'; return ;;
      *) log_warning "Invalid selection. Please enter y or n." ;;
    esac
  done
}

read_existing_zigbee_value() {
  local config_key="$1"
  local target_file="${TARGET_OPENHAB_CONFIG_DIR}/things/zigbee.things"

  [[ -f "${target_file}" ]] || return 1
  sed -nE "s/^[[:space:]]*${config_key}=\"?([^\",]+)\"?,?$/\1/p" "${target_file}" | head -n 1
}

generate_hex_secret() {
  od -An -N "$1" -tx1 /dev/urandom | tr -d ' \n'
}

generate_zigbee_pan_id() {
  local pan_id
  pan_id="$(od -An -N 2 -tu2 /dev/urandom | tr -d ' ')"
  printf '%s\n' "$((pan_id % 65534 + 1))"
}

resolve_configured_value() {
  local env_name="$1"
  local config_key="$2"
  local generated_value="$3"
  local existing_value

  if [[ -n "${!env_name:-}" ]]; then
    printf '%s\n' "${!env_name}"
    return
  fi
  existing_value="$(read_existing_zigbee_value "${config_key}" || true)"
  printf '%s\n' "${existing_value:-${generated_value}}"
}

validate_decimal_range() {
  local name="$1" value="$2" min="$3" max="$4"
  [[ "${value}" =~ ^[0-9]+$ ]] || fail "${name} must be a decimal number between ${min} and ${max}: ${value}"
  (( value >= min && value <= max )) || fail "${name} must be between ${min} and ${max}: ${value}"
}

validate_hex_length() {
  local name="$1" value="$2" expected_length="$3"
  [[ "${value}" =~ ^[0-9A-Fa-f]{${expected_length}}$ ]] \
    || fail "${name} must be ${expected_length} hexadecimal characters: ${value}"
}

resolve_zigbee_port() {
  local serial_device
  local serial_devices=()

  if [[ -n "${CAMPERPILOT_ZIGBEE_PORT:-}" ]]; then
    [[ -e "${CAMPERPILOT_ZIGBEE_PORT}" ]] || fail "Configured Zigbee port does not exist: ${CAMPERPILOT_ZIGBEE_PORT}"
    printf '%s\n' "${CAMPERPILOT_ZIGBEE_PORT}"
    return
  fi
  if [[ -d /dev/serial/by-id ]]; then
    while IFS= read -r -d '' serial_device; do
      serial_devices+=("${serial_device}")
    done < <(find /dev/serial/by-id -maxdepth 1 -type l -print0 | sort -z)
  fi
  case "${#serial_devices[@]}" in
    0) fail "No Zigbee serial device found in /dev/serial/by-id. Set CAMPERPILOT_ZIGBEE_PORT=/dev/serial/by-id/<device> and rerun the installer." ;;
    1) printf '%s\n' "${serial_devices[0]}" ;;
    *)
      log_error "Multiple serial devices found in /dev/serial/by-id."
      for serial_device in "${serial_devices[@]}"; do log_error "  ${serial_device}"; done
      fail "Set CAMPERPILOT_ZIGBEE_PORT=/dev/serial/by-id/<device> and rerun the installer."
      ;;
  esac
}

install_zigbee_configuration() {
  local source_file="${SOURCE_OPENHAB_CONFIG_DIR}/things/zigbee.things"
  local target_file="${TARGET_OPENHAB_CONFIG_DIR}/things/zigbee.things"
  local zigbee_port zigbee_pan_id zigbee_extended_pan_id zigbee_network_key

  if [[ "${INSTALL_ZIGBEE:-0}" -ne 1 ]]; then
    log_success "Skipping optional Zigbee things configuration."
    return
  fi

  validate_source_file "${source_file}"
  zigbee_port="$(resolve_zigbee_port)"
  zigbee_pan_id="$(resolve_configured_value CAMPERPILOT_ZIGBEE_PAN_ID zigbee_panid "$(generate_zigbee_pan_id)")"
  zigbee_extended_pan_id="$(resolve_configured_value CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID zigbee_extendedpanid "$(generate_hex_secret 8)")"
  zigbee_network_key="$(resolve_configured_value CAMPERPILOT_ZIGBEE_NETWORK_KEY zigbee_networkkey "$(generate_hex_secret 16)")"

  validate_decimal_range CAMPERPILOT_ZIGBEE_PAN_ID "${zigbee_pan_id}" 1 65534
  validate_hex_length CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID "${zigbee_extended_pan_id}" 16
  validate_hex_length CAMPERPILOT_ZIGBEE_NETWORK_KEY "${zigbee_network_key}" 32

  log_success "Installing Zigbee things configuration..."
  install -d -o openhab -g openhab -m "${OPENHAB_CONFIG_DIR_MODE}" "${TARGET_OPENHAB_CONFIG_DIR}/things"
  sed \
    -e "s|${ZIGBEE_PORT_PLACEHOLDER}|${zigbee_port}|g" \
    -e "s|${ZIGBEE_PAN_ID_PLACEHOLDER}|${zigbee_pan_id}|g" \
    -e "s|${ZIGBEE_EXTENDED_PAN_ID_PLACEHOLDER}|${zigbee_extended_pan_id}|g" \
    -e "s|${ZIGBEE_NETWORK_KEY_PLACEHOLDER}|${zigbee_network_key}|g" \
    "${source_file}" \
    | install -o openhab -g openhab -m "${OPENHAB_CONFIG_FILE_MODE}" /dev/stdin "${target_file}"
  verify_installed_file "${target_file}" "664" "openhab:openhab"
  log_success "Installed zigbee.things with Zigbee port ${zigbee_port}"
}
