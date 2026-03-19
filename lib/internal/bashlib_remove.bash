#!/usr/bin/env bash
# Internal shared library for remove command

## SOURCE GUARD bashlib_remove.bash -----------------------------------------------------
if [[ -v installer_remove_sourced ]]; then
    return 0
fi
installer_remove_sourced=1
## ---------------------------------------------------------------------------------------

_confirm_remove() {
    local target="$1"
    local kind="$2"
    local reply

    [[ -e "$target" || -L "$target" ]] || return 1

    printf "%b[REMOVE]:%b Remove %s %b%s%b? [y/N] " \
           "${installer_yellow}" "${installer_reset}" "$kind" "${installer_magenta}" "$target" "${installer_reset}"
    read -r reply

    case "$reply" in
        y|Y|yes|YES)
            if [[ "$kind" == "directory" ]]; then
                rm -r -- "$target" || return 1
            else
                rm -f -- "$target" || return 1
            fi
            printf "removed %s\n" "$target"
            return 0
            ;;
        *)
            printf "skipped %s\n" "$target"
            return 0
            ;;
    esac
}

_remove_local() {
    local rc=0
    local local_bin="$HOME/.local/bin/$TOOL_NAME"
    local local_lib="$HOME/.local/lib/$TOOL_NAME"
    local local_exec="$HOME/.local/libexec/$TOOL_NAME"

    [[ -f "$local_bin" || -L "$local_bin" ]] && { _confirm_remove "$local_bin" "file" || rc=1; }
    [[ -d "$local_lib" ]] && { _confirm_remove "$local_lib" "directory" || rc=1; }
    [[ -d "$local_exec" ]] && { _confirm_remove "$local_exec" "directory" || rc=1; }

    return "$rc"
}

_remove_global() {
    local rc=0
    local global_bin="/usr/local/bin/$TOOL_NAME"
    local global_lib="/usr/local/lib/$TOOL_NAME"
    local global_exec="/usr/local/libexec/$TOOL_NAME"

    [[ -f "$global_bin" || -L "$global_bin" ]] && { _confirm_remove "$global_bin" "file" || rc=1; }
    [[ -d "$global_lib" ]] && { _confirm_remove "$global_lib" "directory" || rc=1; }
    [[ -d "$global_exec" ]] && { _confirm_remove "$global_exec" "directory" || rc=1; }

    return "$rc"
}

# bashlib_remove_tool <tool name>
# Remove the named tool from standard install locations. The caller
# (typically a libexec wrapper) should handle argument parsing and
# logging setup. Returns 0 on success.
bashlib_remove_tool() {
    local tool_name="$1"
    local rc=0

    if [[ -z "$tool_name" ]]; then
        installer_error "missing project name"
        return 1
    fi

    installer_logln "Checking standard install locations for $tool_name..."

    # set TOOL_NAME for the helper functions used above
    local TOOL_NAME="$tool_name"

    # call helpers (they reference TOOL_NAME variable)
    _remove_local || rc=1
    _remove_global || rc=1

    if [ "$rc" -eq 0 ]; then
        installer_logln "Remove finished."
        return 0
    else
        installer_error "Failed to remove $tool_name"
        return 1
    fi
}
