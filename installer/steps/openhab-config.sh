#!/usr/bin/env bash

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

install_openhab_config_things() {
  log_success "Installing openHAB things configuration..."
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
