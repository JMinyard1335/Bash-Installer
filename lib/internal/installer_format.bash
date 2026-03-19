#!/usr/bin/env bash

## Source guard do not remove
if [[ -v installer_format_sourced ]]; then
    return 0
fi
installer_format_sourced=1
## End Source Guard

installer_green="\e[32m"
installer_red="\e[31m"
installer_yellow="\e[33m"
installer_cyan="\e[36m"
installer_magenta="\e[35m"
installer_reset="\e[0m"

# Prints a normal message with a cyan installer tag. (no newline)
installer_log() {
    printf "${installer_cyan}[Installer]:${installer_reset} %s" "$*" >&2
}

# Prints a normal message with a cyan installer tag.
installer_logln() {
    printf "${installer_cyan}[Installer]:${installer_reset} %s\n" "$*" >&2
}

# Prints a magenta path, useful with installer_log
installer_path() {
    printf "${installer_magenta}%s${installer_reset}" "$*" >&2
}

# Prints an error message with a red installer tag.
installer_error() {
    printf "${installer_red}[Error]:${installer_reset} %s\n" "$*" >&2
}

# Prints a success message with a green installer tag.
installer_ok() {
    printf "${installer_green}[Ok]:${installer_reset} %s\n" "$*" >&2
}

# Prints a warning message with a yellow installer tag.
installer_warn() {
    printf "${installer_yellow}[Warn]:${installer_reset} %s\n" "$*" >&2
}
