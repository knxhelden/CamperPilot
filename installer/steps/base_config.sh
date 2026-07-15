#!/usr/bin/env bash

readonly DEFAULT_HOSTNAME="camperpilot"
readonly DEFAULT_TIMEZONE="Europe/Berlin"

is_valid_hostname() {
  local hostname="$1"

  [[ ${#hostname} -ge 1 && ${#hostname} -le 63 ]] || return 1
  [[ "$hostname" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || return 1
}

read_target_hostname() {
  local hostname

  while true; do
    if [[ -t 0 ]]; then
      read -r -p "Hostname [${DEFAULT_HOSTNAME}]: " hostname
    else
      hostname=""
    fi

    hostname="${hostname:-$DEFAULT_HOSTNAME}"

    if is_valid_hostname "$hostname"; then
      printf '%s\n' "$hostname"
      return
    fi

    log_warning "Invalid hostname. Use 1-63 letters, numbers or hyphens; start and end with a letter or number."
  done
}

read_openhabian_password() {
  local password
  local password_confirmation

  if [[ ! -t 0 ]]; then
    fail "Cannot read the openhabian password without an interactive terminal."
  fi

  while true; do
    read -r -s -p "New password for openhabian: " password
    printf '\n' >&2
    read -r -s -p "Repeat password for openhabian: " password_confirmation
    printf '\n' >&2

    if [[ -z "$password" ]]; then
      log_warning "Password must not be empty."
      continue
    fi

    if [[ "$password" == "$password_confirmation" ]]; then
      printf '%s\n' "$password"
      return
    fi

    log_warning "Passwords do not match. Please try again."
  done
}

configure_openhabian_password() {
  local password

  password="$(read_openhabian_password)"

  log_success "Setting password for openhabian user..."
  printf 'openhabian:%s\n' "$password" | chpasswd
}

configure_hostname() {
  local target_hostname="$1"
  local current_hostname

  current_hostname="$(hostnamectl --static 2>/dev/null || hostname)"

  if [[ "$current_hostname" == "$target_hostname" ]]; then
    log_success "Hostname is already set to ${target_hostname}."
    return
  fi

  log_success "Setting hostname to ${target_hostname}..."
  hostnamectl set-hostname "$target_hostname"
}

configure_timezone() {
  local current_timezone

  current_timezone="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"

  if [[ "$current_timezone" == "$DEFAULT_TIMEZONE" ]]; then
    log_success "Timezone is already set to ${DEFAULT_TIMEZONE}."
    return
  fi

  log_success "Setting timezone to ${DEFAULT_TIMEZONE}..."
  timedatectl set-timezone "$DEFAULT_TIMEZONE"
}

install_base_configuration() {
  local target_hostname

  target_hostname="$(read_target_hostname)"

  configure_hostname "$target_hostname"
  configure_timezone
  configure_openhabian_password
}
