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
  local actual_owner
  local actual_mode

  actual_owner="$(stat -c '%U:%G' "$file")"
  actual_mode="$(stat -c '%a' "$file")"

  [[ "$actual_owner" == "root:root" ]] \
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

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    fail "Run this installer as root: sudo ./install.sh"
  fi
}

download_repository() {
  if [[ -d "${LOCAL_REPO_DIR}/.git" ]]; then
    log_success "Updating CamperPilot repository in ${LOCAL_REPO_DIR}..."
    git -C "${LOCAL_REPO_DIR}" fetch --depth 1 origin "${REPOSITORY_BRANCH}"
    git -C "${LOCAL_REPO_DIR}" checkout -B "${REPOSITORY_BRANCH}" "FETCH_HEAD"
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
}

load_installer_steps() {
  local installer_dir="${SOURCE_DIR}/installer"

  if [[ ! -f "${installer_dir}/steps/system_scripts.sh" || ! -f "${installer_dir}/steps/sudoers.sh" ]]; then
    require_command git
    download_repository
    installer_dir="${LOCAL_REPO_DIR}/installer"
  fi

  # shellcheck source=installer/steps/system_scripts.sh
  source "${installer_dir}/steps/system_scripts.sh"
  # shellcheck source=installer/steps/sudoers.sh
  source "${installer_dir}/steps/sudoers.sh"
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

install_camperpilot() {
  require_command git

  download_repository
  load_installer_steps

  require_root
  require_command install
  require_command stat
  require_command visudo
  require_command grep
  require_command id

  id openhab >/dev/null 2>&1 \
    || fail "The system user 'openhab' does not exist."

  install_system_scripts
  install_sudoers_configuration

  log_success "Installation completed successfully."
  log_success "Installed:"
  log_success "  ${TARGET_SCRIPT_DIR}/camperpilot-poweroff"
  log_success "  ${TARGET_SCRIPT_DIR}/camperpilot-reboot"
  log_success "  ${TARGET_SUDOERS_DIR}/camperpilot-openhab"
}

uninstall_camperpilot() {
  load_installer_steps

  require_root
  require_command rm

  log_success "Uninstalling CamperPilot system files..."

  uninstall_system_scripts
  uninstall_sudoers_configuration

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
