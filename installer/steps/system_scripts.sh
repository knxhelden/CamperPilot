#!/usr/bin/env bash

install_system_scripts() {
  local script_name

  for script_name in "${SCRIPTS[@]}"; do
    validate_source_file "${SOURCE_SCRIPT_DIR}/${script_name}"
  done

  log_success "Installing system scripts..."
  install -d -o root -g root -m 0755 "$TARGET_SCRIPT_DIR"

  for script_name in "${SCRIPTS[@]}"; do
    install \
      -o root \
      -g root \
      -m 0750 \
      "${SOURCE_SCRIPT_DIR}/${script_name}" \
      "${TARGET_SCRIPT_DIR}/${script_name}"
  done

  for script_name in "${SCRIPTS[@]}"; do
    verify_installed_file "${TARGET_SCRIPT_DIR}/${script_name}" "750"
  done
}

uninstall_system_scripts() {
  local script_name

  for script_name in "${SCRIPTS[@]}"; do
    uninstall_file "${TARGET_SCRIPT_DIR}/${script_name}"
  done
}
