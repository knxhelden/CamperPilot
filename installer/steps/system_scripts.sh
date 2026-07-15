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

install_sudoers_configuration() {
  validate_source_file "${SOURCE_SCRIPT_DIR}/${SUDOERS_FILE}"

  log_success "Validating sudoers configuration..."
  visudo -cf "${SOURCE_SCRIPT_DIR}/${SUDOERS_FILE}"

  log_success "Installing sudoers configuration..."
  install -d -o root -g root -m 0755 "$TARGET_SUDOERS_DIR"

  install \
    -o root \
    -g root \
    -m 0440 \
    "${SOURCE_SCRIPT_DIR}/${SUDOERS_FILE}" \
    "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}"

  log_success "Validating installed sudoers configuration..."
  visudo -cf "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}"

  verify_installed_file "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}" "440"
}

uninstall_sudoers_configuration() {
  uninstall_file "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}"
}
