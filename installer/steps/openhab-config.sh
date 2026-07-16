#!/usr/bin/env bash

readonly ZIGBEE_PORT_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_PORT__"
readonly ZIGBEE_PAN_ID_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_PAN_ID__"
readonly ZIGBEE_EXTENDED_PAN_ID_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID__"
readonly ZIGBEE_NETWORK_KEY_PLACEHOLDER="__CAMPERPILOT_ZIGBEE_NETWORK_KEY__"
readonly OPENHAB_CONFIG_DIR_MODE="2775"
readonly OPENHAB_CONFIG_FILE_MODE="0664"

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

read_existing_zigbee_value() {
  local config_key="$1"
  local target_file="${TARGET_OPENHAB_CONFIG_DIR}/things/zigbee.things"

  [[ -f "${target_file}" ]] || return 1

  sed -nE "s/^[[:space:]]*${config_key}=\"?([^\",]+)\"?,?$/\1/p" "${target_file}" | head -n 1
}

generate_hex_secret() {
  local byte_count="$1"

  od -An -N "${byte_count}" -tx1 /dev/urandom | tr -d ' \n'
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
  if [[ -n "${existing_value}" ]]; then
    printf '%s\n' "${existing_value}"
    return
  fi

  printf '%s\n' "${generated_value}"
}

validate_decimal_range() {
  local name="$1"
  local value="$2"
  local min="$3"
  local max="$4"

  [[ "${value}" =~ ^[0-9]+$ ]] \
    || fail "${name} must be a decimal number between ${min} and ${max}: ${value}"
  (( value >= min && value <= max )) \
    || fail "${name} must be between ${min} and ${max}: ${value}"
}

validate_hex_length() {
  local name="$1"
  local value="$2"
  local expected_length="$3"

  [[ "${value}" =~ ^[0-9A-Fa-f]{${expected_length}}$ ]] \
    || fail "${name} must be ${expected_length} hexadecimal characters: ${value}"
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

render_zigbee_thing_file() {
  local source_file="$1"
  local target_file="$2"
  local zigbee_port
  local zigbee_pan_id
  local zigbee_extended_pan_id
  local zigbee_network_key

  zigbee_port="$(resolve_zigbee_port)"
  zigbee_pan_id="$(resolve_configured_value CAMPERPILOT_ZIGBEE_PAN_ID zigbee_panid "$(generate_zigbee_pan_id)")"
  zigbee_extended_pan_id="$(resolve_configured_value CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID zigbee_extendedpanid "$(generate_hex_secret 8)")"
  zigbee_network_key="$(resolve_configured_value CAMPERPILOT_ZIGBEE_NETWORK_KEY zigbee_networkkey "$(generate_hex_secret 16)")"

  validate_decimal_range CAMPERPILOT_ZIGBEE_PAN_ID "${zigbee_pan_id}" 1 65534
  validate_hex_length CAMPERPILOT_ZIGBEE_EXTENDED_PAN_ID "${zigbee_extended_pan_id}" 16
  validate_hex_length CAMPERPILOT_ZIGBEE_NETWORK_KEY "${zigbee_network_key}" 32

  sed \
    -e "s|${ZIGBEE_PORT_PLACEHOLDER}|${zigbee_port}|g" \
    -e "s|${ZIGBEE_PAN_ID_PLACEHOLDER}|${zigbee_pan_id}|g" \
    -e "s|${ZIGBEE_EXTENDED_PAN_ID_PLACEHOLDER}|${zigbee_extended_pan_id}|g" \
    -e "s|${ZIGBEE_NETWORK_KEY_PLACEHOLDER}|${zigbee_network_key}|g" \
    "${source_file}" \
    | install -o openhab -g openhab -m "${OPENHAB_CONFIG_FILE_MODE}" /dev/stdin "${target_file}"

  log_success "Installed zigbee.things with Zigbee port ${zigbee_port}"
}

install_openhab_thing_file() {
  local thing_file="$1"
  local source_file="${SOURCE_OPENHAB_CONFIG_DIR}/things/${thing_file}"
  local target_file="${TARGET_OPENHAB_CONFIG_DIR}/things/${thing_file}"

  if [[ "${thing_file}" == "zigbee.things" ]]; then
    render_zigbee_thing_file "${source_file}" "${target_file}"
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
  )

  if [[ "${INSTALL_ZIGBEE:-0}" -eq 1 ]]; then
    thing_files+=("zigbee.things")
  else
    log_success "Skipping optional Zigbee things configuration."
  fi

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

install_openhab_config_automation() {
  local automation_file
  local automation_files=(
    "camperpilot_system.js"
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
  configure_openhab_config_access
  install_openhab_config_services
  install_openhab_config_sitemaps
  install_openhab_config_things
  install_openhab_config_items
  install_openhab_config_automation
}
