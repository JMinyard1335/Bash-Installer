#!/usr/bin/env bash
# Used in the installer tool to install the desired path to your system.
#
# Uses the tool.toml file to get the tool file name.
#
# Local installs go to:
#   ~/.local/bin
#   ~/.local/lib
#
# Global installs go to:
#   /usr/bin
#   /usr/lib

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/toml.sh"
source "${SCRIPT_DIR}/installer-color.sh"

# Set to false by default so tools go to local install.
INSTALL_GLOBAL=false
# path where the tool will be installed. (/user/, ~/.local/)
# Set based on the INSTALL_GLOBAL flag.
INSTALL_LOCATION=""			
TOOL_PATH=""				# Path to the tools project.

_install_usage() {
    cat <<EOF
Usage:
  installer install [options] <path>

Options:
  -g, --global     Install globally
  --help           Show this help message

Behavior:
  Expects a project layout like:
    <project-root>/<tool-name>
    <project-root>/tool.toml
    <project-root>/lib/

  Installs:
    <tool-name> -> <prefix>/bin/<tool-name>
    lib/        -> <prefix>/lib/<tool-name>/
    tool.toml   -> <prefix>/lib/<tool-name>/tool.toml

Examples:
  installer install ./installer
  installer install --global ./installer
EOF
}

## Logging functions ------------------------------------------------------------------------
_install_log() {
    printf "${CYAN}[install]:${RESET} %s\n" "$*"
}

_install_error() {
    printf "${RED}[install-Err]:${RESET} %s\n" "$*" >&2
}


_install_warn() {
    printf "${YELLOW}[install-Warn]:${RESET} %s\n" "$*" >&2
}

_install_success() {
    printf "${GREEN}[install-Ok]:${RESET} %s\n" "$*"
}

## ------------------------------------------------------------------------------------------
# _install_parse_args <args...>
# Parses:
#   -g | --global
#   --help
#   <path>
_install_parse_args() {
    TOOL_PATH=""
    INSTALL_GLOBAL=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                _install_usage
                return 2
                ;;
            -g|--global)
                INSTALL_GLOBAL=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                _install_error "Unknown option: $1"
                _install_usage
                return 1
                ;;
            *)
                if [[ -n "$TOOL_PATH" ]]; then
                    _install_error "Too many arguments: $1"
                    _install_usage
                    return 1
                fi
                TOOL_PATH="$1"
                shift
                ;;
        esac
    done

    while [[ $# -gt 0 ]]; do
        if [[ -n "$TOOL_PATH" ]]; then
            _install_error "Too many arguments: $1"
            _install_usage
            return 1
        fi
        TOOL_PATH="$1"
        shift
    done

    if [[ -z "$TOOL_PATH" ]]; then
        _install_error "Missing install path."
        _install_usage
        return 1
    fi

    return 0
}

# _install_get_dir() <global-flag>
# if the global flag is true the install
# location is set to /usr/ else ~/.local
_install_get_dir() {
    local global="$1"
    if [[ "$global" == true ]]; then
	INSTALL_LOCATION="/usr/"
    else
	INSTALL_LOCATION="$HOME/.local/"
    fi
}

# _install_check_dir <install-location>
# creates the lib and bin folders in the
# install location if they don't exist
_install_check_dir() {
    local install_loc="$1"
    # Check for lib
    if [[ ! -d "${install_loc}/lib" ]]; then
	_install_warn "${install_loc}/lib does not exist"
	mkdir -p "${install_loc}/lib" || return 1
	_install_success "${install_loc}/lib created."
    fi
    
    # check for bin
    if [[ ! -d "${install_loc}/bin" ]]; then
	_install_warn "${install_loc}/bin does not exist"
	mkdir -p "${install_loc}/bin" || return 1
	_install_success "${install_loc}/bin created."
    fi
}

# _install_move_to_bin <Path to tool> <tool name>
# moves the tool from the project dir to install bin.
# final dir is /install-path/bin/tool
_install_move_to_bin() {
    local path="$1"
    local tool="$2"

    # install the tool script to the bin
    # grants the necessary permissions
    if [[ -f "${path}/${tool}" ]]; then
	install -m 755 -t "${INSTALL_LOCATION}/bin" "${path}/${tool}" || return 1
	_install_success "$tool installed successfully to bin"
	return 0
    fi
    
    return 1
}

# _install_move_to_lib <Path to tool> <tool>
# moves the tools lib folder from the project dir to install lib
# final dir is /install-path/lib/tool/{files}
_install_move_to_lib() {
    local path="$1"
    local tool="$2"
    local dest="${INSTALL_LOCATION}/lib/${tool}/"
    
    ## install the tools lib to the lib dir.
    if [[ -d "${path}/lib/" ]]; then
	install -d "$dest" || return 1
	cp -r "${path}/lib/." "$dest" || return 1
	_install_success "${path}/lib copied successfully"
	return 0
    fi
    
    return 1
}

# _install_move_metadata <Path to tool> <tool>
# moves the tool.toml metadata file from the project root
# to the install lib dir.
# final dir is /install-path/lib/tool/tool.toml
_install_move_metadata() {
    local path="$1"
    local tool="$2"

    if [[ ! -f "${path}/tool.toml" ]]; then
        _install_error "tool.toml not found in ${path}"
        return 1
    fi

    install -m 644 "${path}/tool.toml" "${INSTALL_LOCATION}/lib/${tool}/tool.toml" || return 1
    return 0
}

# install_cmd
# the front facing api of this script.
install_cmd() {
    local tool=""
    local parse_status=0

    _install_parse_args "$@"
    parse_status=$?

    case "$parse_status" in
        0) ;;
        1) return 1 ;;
        2) return 0 ;;
        *) return 1 ;;
    esac

    tool="$(toml_r "$TOOL_PATH/tool.toml" project name)" || return 1

    _install_log "Installing $tool..."

    _install_get_dir "$INSTALL_GLOBAL"
    _install_log "Installing to $INSTALL_LOCATION"

    _install_check_dir "$INSTALL_LOCATION" || return 1
    _install_move_to_bin "$TOOL_PATH" "$tool" || return 1
    _install_move_to_lib "$TOOL_PATH" "$tool" || return 1
    _install_move_metadata "$TOOL_PATH" "$tool" || return 1

    _install_success "$tool successfully installed."
    echo ""
    _install_warn 'READ THE FOLLOWING:'
    _install_warn 'If installed locally:'
    _install_warn '  add '"${MAGENTA}"'$HOME/.local/bin'"${RESET}"' to your PATH'
    echo ""
    _install_log 'add '"${MAGENTA}"'export PATH="$PATH:$HOME/.local/bin"'"${RESET}"' to your .bashrc file.'
    _install_log '.bashrc can be found at: '"${MAGENTA}"'~/.bashrc'"${RESET}"
}
