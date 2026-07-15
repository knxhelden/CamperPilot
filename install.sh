#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly LOCAL_REPO_DIR="${SOURCE_DIR}/CamperPilot"
readonly REPOSITORY_URL="${CAMPERPILOT_REPOSITORY_URL:-https://github.com/knxhelden/CamperPilot.git}"
readonly REPOSITORY_BRANCH="${CAMPERPILOT_REPOSITORY_BRANCH:-main}"
readonly SOURCE_SCRIPT_DIR="${LOCAL_REPO_DIR}/scripts"
readonly TARGET_SCRIPT_DIR="/usr/local/sbin"
readonly TARGET_SUDOERS_DIR="/etc/sudoers.d"

readonly SCRIPTS=(
  "camperpilot-poweroff"
  "camperpilot-reboot"
)

readonly SUDOERS_FILE="camperpilot-openhab"

log() {
  printf '[CamperPilot] %s\n' "$*"
}

fail() {
  printf '[CamperPilot] ERROR: %s\n' "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  printf '[CamperPilot] ERROR: Operation failed in line %s (exit code %s).\n' \
    "${BASH_LINENO[0]}" "$exit_code" >&2
  exit "$exit_code"
}

trap on_error ERR

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    fail "Run this installer as root: sudo ./install.sh"
  fi
}

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

download_repository() {
  if [[ -d "${LOCAL_REPO_DIR}/.git" ]]; then
    log "Updating CamperPilot repository in ${LOCAL_REPO_DIR}..."
    git -C "${LOCAL_REPO_DIR}" fetch --depth 1 origin "${REPOSITORY_BRANCH}"
    git -C "${LOCAL_REPO_DIR}" checkout -B "${REPOSITORY_BRANCH}" "FETCH_HEAD"
    return
  fi

  if [[ -e "${LOCAL_REPO_DIR}" ]]; then
    fail "Target path already exists and is not a Git repository: ${LOCAL_REPO_DIR}"
  fi

  log "Downloading CamperPilot repository to ${LOCAL_REPO_DIR}..."
  git clone \
    --depth 1 \
    --branch "${REPOSITORY_BRANCH}" \
    "${REPOSITORY_URL}" \
    "${LOCAL_REPO_DIR}"
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
      *) printf '[CamperPilot] Invalid selection. Please enter 1 or 2.\n' >&2 ;;
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
Usage: sudo ./install.sh [install|uninstall]

Without an argument, the interactive main menu is shown.

Options:
  install      Install CamperPilot system scripts and sudoers configuration.
  uninstall    Remove CamperPilot system scripts and sudoers configuration.
  -h, --help   Show this help text.
HELP
      exit 0
      ;;
    *) fail "Unknown action: $action. Use install, uninstall or --help." ;;
  esac
}

verify_installed_file() {
  local file="$1"
  local expected_mode="$2"
  local actual_owner
  local actual_mode

  actual_owner="$(stat -c '%U:%G' "$file")"
  actual_mode="$(stat -c '%a' "$file")"

  [[ "$actual_owner" == "root:root" ]] \
    || fail "Unexpected owner for $file: $actual_owner"

  [[ "$actual_mode" == "$expected_mode" ]] \
    || fail "Unexpected permissions for $file: $actual_mode"
}

install_camperpilot() {
  require_command git

  download_repository

  require_root
  require_command install
  require_command stat
  require_command visudo
  require_command grep
  require_command id

  id openhab >/dev/null 2>&1 \
    || fail "The system user 'openhab' does not exist."

  for script_name in "${SCRIPTS[@]}"; do
    validate_source_file "${SOURCE_SCRIPT_DIR}/${script_name}"
  done

  validate_source_file "${SOURCE_SCRIPT_DIR}/${SUDOERS_FILE}"

  log "Validating sudoers configuration..."
  visudo -cf "${SOURCE_SCRIPT_DIR}/${SUDOERS_FILE}"

  log "Installing system scripts..."
  install -d -o root -g root -m 0755 "$TARGET_SCRIPT_DIR"

  for script_name in "${SCRIPTS[@]}"; do
    install \
      -o root \
      -g root \
      -m 0750 \
      "${SOURCE_SCRIPT_DIR}/${script_name}" \
      "${TARGET_SCRIPT_DIR}/${script_name}"
  done

  log "Installing sudoers configuration..."
  install -d -o root -g root -m 0755 "$TARGET_SUDOERS_DIR"

  install \
    -o root \
    -g root \
    -m 0440 \
    "${SOURCE_SCRIPT_DIR}/${SUDOERS_FILE}" \
    "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}"

  log "Validating installed sudoers configuration..."
  visudo -cf "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}"

  for script_name in "${SCRIPTS[@]}"; do
    verify_installed_file "${TARGET_SCRIPT_DIR}/${script_name}" "750"
  done

  verify_installed_file "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}" "440"

  log "Installation completed successfully."
  log "Installed:"
  log "  ${TARGET_SCRIPT_DIR}/camperpilot-poweroff"
  log "  ${TARGET_SCRIPT_DIR}/camperpilot-reboot"
  log "  ${TARGET_SUDOERS_DIR}/camperpilot-openhab"
}

uninstall_file() {
  local file="$1"

  if [[ -e "$file" ]]; then
    rm -f -- "$file"
    log "Removed $file"
    return
  fi

  log "Already absent: $file"
}

uninstall_camperpilot() {
  require_root
  require_command rm

  log "Uninstalling CamperPilot system files..."

  for script_name in "${SCRIPTS[@]}"; do
    uninstall_file "${TARGET_SCRIPT_DIR}/${script_name}"
  done

  uninstall_file "${TARGET_SUDOERS_DIR}/${SUDOERS_FILE}"

  log "Uninstallation completed successfully."
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
