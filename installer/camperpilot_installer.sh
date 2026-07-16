#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "${SOURCE_DIR}/../openhab" && -d "${SOURCE_DIR}/../scripts" ]]; then
  readonly LOCAL_REPO_DIR="$(cd -- "${SOURCE_DIR}/.." && pwd)"
  readonly REPOSITORY_IS_INSTALLER_MANAGED=0
else
  readonly LOCAL_REPO_DIR="${SOURCE_DIR}/CamperPilot"
  readonly REPOSITORY_IS_INSTALLER_MANAGED=1
fi

readonly REPOSITORY_URL="${CAMPERPILOT_REPOSITORY_URL:-https://github.com/knxhelden/CamperPilot.git}"
readonly REPOSITORY_BRANCH="${CAMPERPILOT_REPOSITORY_BRANCH:-main}"
readonly SOURCE_SCRIPT_DIR="${LOCAL_REPO_DIR}/scripts"
readonly SOURCE_OPENHAB_CONFIG_DIR="${LOCAL_REPO_DIR}/openhab"
readonly TARGET_SCRIPT_DIR="/usr/local/sbin"
readonly TARGET_OPENHAB_CONFIG_DIR="/etc/openhab"
readonly TARGET_SUDOERS_DIR="/etc/sudoers.d"

readonly SCRIPTS=(
  "camperpilot-poweroff"
  "camperpilot-reboot"
)

readonly SUDOERS_FILE="camperpilot-openhab"

readonly OPENHAB_CONFIG_FILES=(
  "services/addons.cfg"
  "things/systeminfo.things"
  "things/bluetooth.things"
  "things/zigbee.things"
  "items/climate.items"
  "items/resources.items"
  "items/security.items"
  "items/structure.items"
  "items/system.items"
  "persistence/mapdb.persist"
  "automation/js/camperpilot_system.js"
  "automation/js/temperature_alarm.js"
  "sitemaps/camperpilot.sitemap"
)

REPOSITORY_SYNCED=$((1 - REPOSITORY_IS_INSTALLER_MANAGED))

if [[ -z "${NO_COLOR:-}" && ( -t 1 || -t 2 ) ]]; then
  readonly COLOR_GREEN=$'\033[32m'
  readonly COLOR_YELLOW=$'\033[33m'
  readonly COLOR_RED=$'\033[31m'
  readonly COLOR_RESET=$'\033[0m'
else
  readonly COLOR_GREEN=""
  readonly COLOR_YELLOW=""
  readonly COLOR_RED=""
  readonly COLOR_RESET=""
fi

log_success() {
  printf '%s[CamperPilot] %s%s\n' "$COLOR_GREEN" "$*" "$COLOR_RESET"
}

log_warning() {
  printf '%s[CamperPilot] WARNING: %s%s\n' "$COLOR_YELLOW" "$*" "$COLOR_RESET" >&2
}

log_error() {
  printf '%s[CamperPilot] ERROR: %s%s\n' "$COLOR_RED" "$*" "$COLOR_RESET" >&2
}

fail() {
  log_error "$*"
  exit 1
}

on_error() {
  local exit_code=$?
  log_error "Operation failed in line ${BASH_LINENO[0]} (exit code ${exit_code})."
  exit "$exit_code"
}

trap on_error ERR

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

validate_source_file() {
  local file="$1"

  [[ -f "$file" ]] || fail "Required file not found: $file"

  if grep -q $'\r' "$file"; then
    fail "Windows line endings detected in $file. Convert the file to Unix LF."
  fi
}

verify_installed_file() {
  local file="$1"
  local expected_mode="$2"
  local expected_owner="${3:-root:root}"
  local actual_owner
  local actual_mode

  actual_owner="$(stat -c '%U:%G' "$file")"
  actual_mode="$(stat -c '%a' "$file")"

  [[ "$actual_owner" == "$expected_owner" ]] \
    || fail "Unexpected owner for $file: $actual_owner"

  [[ "$actual_mode" == "$expected_mode" ]] \
    || fail "Unexpected permissions for $file: $actual_mode"
}

uninstall_file() {
  local file="$1"

  if [[ -e "$file" ]]; then
    rm -f -- "$file"
    log_success "Removed $file"
    return
  fi

  log_warning "Already absent: $file"
}

uninstall_local_repository() {
  if [[ "${REPOSITORY_IS_INSTALLER_MANAGED}" -eq 0 ]]; then
    log_warning "Local CamperPilot checkout retained: ${LOCAL_REPO_DIR}"
    return
  fi

  if [[ -e "${LOCAL_REPO_DIR}" || -L "${LOCAL_REPO_DIR}" ]]; then
    rm -rf -- "${LOCAL_REPO_DIR}"
    log_success "Removed cloned repository ${LOCAL_REPO_DIR}"
    return
  fi

  log_warning "Already absent: ${LOCAL_REPO_DIR}"
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    fail "Run this installer as root: sudo ./installer/camperpilot_installer.sh"
  fi
}

download_repository() {
  if [[ "${REPOSITORY_SYNCED}" -eq 1 ]]; then
    if [[ "${REPOSITORY_IS_INSTALLER_MANAGED}" -eq 0 ]]; then
      log_success "Using CamperPilot checkout in ${LOCAL_REPO_DIR}."
    fi
    return
  fi

  if [[ -d "${LOCAL_REPO_DIR}/.git" ]]; then
    log_success "Updating CamperPilot repository in ${LOCAL_REPO_DIR}..."
    git -C "${LOCAL_REPO_DIR}" fetch --depth 1 origin "${REPOSITORY_BRANCH}"
    git -C "${LOCAL_REPO_DIR}" checkout -B "${REPOSITORY_BRANCH}" "FETCH_HEAD"
    REPOSITORY_SYNCED=1
    return
  fi

  if [[ -e "${LOCAL_REPO_DIR}" ]]; then
    fail "Target path already exists and is not a Git repository: ${LOCAL_REPO_DIR}"
  fi

  log_success "Downloading CamperPilot repository to ${LOCAL_REPO_DIR}..."
  git clone \
    --depth 1 \
    --branch "${REPOSITORY_BRANCH}" \
    "${REPOSITORY_URL}" \
    "${LOCAL_REPO_DIR}"

  REPOSITORY_SYNCED=1
}

load_installer_steps() {
  local installer_dir="${SOURCE_DIR}"

  if [[ ! -f "${installer_dir}/steps/system_scripts.sh" || ! -f "${installer_dir}/steps/base_config.sh" || ! -f "${installer_dir}/steps/openhab-config.sh" || ! -f "${installer_dir}/steps/mopekapro-config.sh" ]]; then
    require_command git
    download_repository
    installer_dir="${LOCAL_REPO_DIR}/installer"
  fi

  # shellcheck source=steps/base_config.sh
  source "${installer_dir}/steps/base_config.sh"
  # shellcheck source=steps/system_scripts.sh
  source "${installer_dir}/steps/system_scripts.sh"
  # shellcheck source=steps/openhab-config.sh
  source "${installer_dir}/steps/openhab-config.sh"
  # shellcheck source=steps/mopekapro-config.sh
  source "${installer_dir}/steps/mopekapro-config.sh"
}

show_main_menu() {
  cat >&2 <<'MENU'

CamperPilot Installer
=====================

Please choose an option:

  1) Install
  2) Uninstall

MENU
}

read_menu_choice() {
  local choice

  while true; do
    show_main_menu
    read -r -p "Selection [1-2]: " choice

    case "$choice" in
      1) printf 'install\n'; return ;;
      2) printf 'uninstall\n'; return ;;
      *) log_warning "Invalid selection. Please enter 1 or 2." ;;
    esac
  done
}

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

resolve_action() {
  local action="${1:-}"

  case "$action" in
    "") ACTION="$(read_menu_choice)" ;;
    install|--install) ACTION="install" ;;
    uninstall|--uninstall) ACTION="uninstall" ;;
    -h|--help)
      cat <<'HELP'
Usage: sudo ./installer/camperpilot_installer.sh [install|uninstall]

Without an argument, the interactive main menu is shown.

Options:
  install      Configure the base system and install CamperPilot system files.
  uninstall    Remove CamperPilot system scripts and sudoers configuration.
  -h, --help   Show this help text.
HELP
      exit 0
      ;;
    *) fail "Unknown action: $action. Use install, uninstall or --help." ;;
  esac
}

install_camperpilot() {
  local INSTALL_ZIGBEE
  local INSTALL_MOPEKAPRO

  require_command git

  download_repository
  load_installer_steps

  require_root
  require_command install
  require_command stat
  require_command visudo
  require_command grep
  require_command find
  require_command sed
  require_command od
  require_command tr
  require_command id
  require_command hostnamectl
  require_command timedatectl
  require_command chpasswd
  require_command usermod

  id openhab >/dev/null 2>&1 \
    || fail "The system user 'openhab' does not exist."

  id openhabian >/dev/null 2>&1 \
    || fail "The system user 'openhabian' does not exist."

  INSTALL_ZIGBEE="$(read_zigbee_choice)"
  INSTALL_MOPEKAPRO="$(read_mopekapro_choice)"

  install_base_configuration
  install_system_scripts
  install_sudoers_configuration
  install_openhab_configuration
  install_mopekapro_configuration

  log_success "Installation completed successfully."
  log_success "Installed:"
  log_success "  ${TARGET_SCRIPT_DIR}/camperpilot-poweroff"
  log_success "  ${TARGET_SCRIPT_DIR}/camperpilot-reboot"
  log_success "  ${TARGET_SUDOERS_DIR}/camperpilot-openhab"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/services/addons.cfg"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/things/systeminfo.things"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/things/bluetooth.things"
  if [[ "${INSTALL_ZIGBEE}" -eq 1 ]]; then
    log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/things/zigbee.things"
  fi
  log_installed_mopekapro_configuration
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/items/climate.items"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/items/resources.items"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/items/security.items"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/items/structure.items"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/items/system.items"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/persistence/mapdb.persist"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/automation/js/camperpilot_system.js"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/automation/js/temperature_alarm.js"
  log_success "  ${TARGET_OPENHAB_CONFIG_DIR}/sitemaps/camperpilot.sitemap"
}

uninstall_camperpilot() {
  local config_file

  load_installer_steps

  require_root
  require_command rm

  log_success "Uninstalling CamperPilot system files..."

  uninstall_system_scripts
  uninstall_sudoers_configuration
  uninstall_local_repository

  log_warning "openHAB configuration files were retained because they may contain manual changes."
  log_warning "Review and remove these files manually if they are no longer needed:"
  for config_file in "${OPENHAB_CONFIG_FILES[@]}"; do
    log_warning "  ${TARGET_OPENHAB_CONFIG_DIR}/${config_file}"
  done
  log_retained_mopekapro_configuration

  log_success "Uninstallation completed successfully."
}

main() {
  local ACTION

  if [[ $# -gt 1 ]]; then
    fail "Too many arguments. Use install, uninstall or --help."
  fi

  resolve_action "${1:-}"

  case "$ACTION" in
    install) install_camperpilot ;;
    uninstall) uninstall_camperpilot ;;
  esac
}

main "$@"
