#!/usr/bin/env bash

# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test_asserts.bash"
source "$SCRIPT_DIR/../lib/internal/bashlib_install.bash"
source "$SCRIPT_DIR/../libexec/bashlib_install"
# -----------------------------------------------------------------------------

test_install_wrapper_resolves_usr_local() {
    echo "Testing install wrapper path resolution for /usr/local..."

    local status=""
    local resolved=""

    (
        # After refactor, this should call a helper like:
        # _installer_resolve_lib_dir "/usr/local/libexec/installer" "installer"
        resolved="$(_installer_resolve_lib_dir "/usr/local/libexec/installer" "installer")"
        assert_str_eq "$resolved" "/usr/local/lib/installer" "wrapper should resolve /usr/local lib dir"
    )
    status="$?"

    assert_true "$status" "resolver should succeed for global /usr/local path"
    echo -e "\e[1;32m[TEST]:\e[0m install_wrapper_resolves_usr_local passed"
}

test_cli_install_main() {
    echo -e "\e[1;36m[TEST]:\e[0m Running installer CLI tests..."
    test_install_wrapper_resolves_usr_local
    echo -e "\e[1;32m[TEST]:\e[0m All installer CLI tests passed!!!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    test_cli_install_main "$@"
fi

