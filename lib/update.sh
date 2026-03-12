#!/usr/bin/env bash
# Used to update a tool from its repo
#
# Determines where the tool is installed.
# reads the tool.toml file from lib/ and
# then clones the repo in that file to a temp
# and runs install on that temp dir.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/toml.sh"
source "${SCRIPT_DIR}/installer-color.sh"
source "${SCRIPT_DIR}/install.sh"

TOOL_NAME=""
TOOL_LOCATION=""

_update_usage() {
    cat <<EOF
Usage:
  installer update [options] <tool>

Options:
  --help	Shows this help menu

Examples:
  installer update installer

EOF
}

_update_error() {
    printf "${RED}[update-Err]:${RESET} %s\n" "$*" >&2
}

_update_warn() {
    printf "${YELLOW}[Warn]:${RESET} %s\n" "$*" >&2
}

_update_info() {
    printf "${CYAN}[Update]:${RESET} %s\n" "$*"
}

_update_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                _update_usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                _update_error "Unknown option: $1"
                _update_usage
                exit 1
                ;;
            *)
                if [[ -n "$TOOL_NAME" ]]; then
                    _update_error "Too many arguments: $1"
                    _update_usage
                    exit 1
                fi
                TOOL_NAME="$1"
                shift
                ;;
        esac
    done

    [[ -n "$TOOL_NAME" ]] || {
        _update_error "Missing tool name"
        _update_usage
        exit 1
    }
}

# _update_Find_tool <tool name>
_update_find_tool() {
    local tool="$1"
    # check local and global installs to determine the install path
    if [[ -f "$HOME/.local/bin/$tool" ]]; then
	TOOL_LOCATION="$HOME/.local/"
	return 0
    elif [[ -f "/usr/bin/$tool" ]]; then
	TOOL_LOCATION="/usr/"
	return 0
    else
	update_error "Tool not found"
	exit 1
    fi
}

update_cmd() {
    _update_parse_args "$@"
    _update_find_tool "$TOOL_NAME"
    repo=$(toml_r "$TOOL_LOCATION/lib/$TOOL_NAME/tool.toml" project repo)
    install_from_repo "$repo" "$TOOL_NAME"
}
