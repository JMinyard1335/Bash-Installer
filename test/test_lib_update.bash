#!/usr/bin/env bash
# Used to test update library functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test_asserts.bash"
source "$SCRIPT_DIR/../lib/internal/bashlib_update.bash"

# -----------------------------------------------------------------------------
# Test sandbox
# -----------------------------------------------------------------------------

TEST_ROOT=""
ORIGINAL_HOME="$HOME"
TOOL_NAME="bashlib_update_test_tool_$$"

setup_test_env() {
    TEST_ROOT="$(mktemp -d)"
    export HOME="$TEST_ROOT/home"

    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/lib"
}

cleanup_test_env() {
    export HOME="$ORIGINAL_HOME"

    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi

    TEST_ROOT=""
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

create_local_tool_bin() {
    local bin_path="$HOME/.local/bin/$TOOL_NAME"

    printf "#!/usr/bin/env bash\n" > "$bin_path"
    chmod +x "$bin_path"
}

create_tool_toml_without_repo() {
    local tool_dir="$HOME/.local/lib/$TOOL_NAME"

    mkdir -p "$tool_dir"
    cat > "$tool_dir/tool.toml" <<EOF
[project]
tool = "$TOOL_NAME"
version = "0.1.0"
EOF
}

create_tool_toml_with_repo() {
    local repo_url="$1"
    local tool_dir="$HOME/.local/lib/$TOOL_NAME"

    mkdir -p "$tool_dir"
    cat > "$tool_dir/tool.toml" <<EOF
[project]
tool = "$TOOL_NAME"
version = "0.1.0"
repo = "$repo_url"
EOF
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

test_find_prefix_local() {
    local status=""
    local prefix=""

    echo "Testing find_prefix local path..."
    cleanup_test_env
    setup_test_env

    create_local_tool_bin

    prefix="$(_bashlib_update_find_prefix "$TOOL_NAME")"
    status="$?"

    assert_true "$status" "find_prefix should succeed when tool is in HOME bin"
    assert_str_eq "$prefix" "$HOME/.local" "find_prefix should return HOME local prefix"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m find_prefix_local passed"
}

test_update_missing_tool_name() {
    local status=""

    echo "Testing update with missing tool name..."
    cleanup_test_env
    setup_test_env

    bashlib_update_tool "" > /dev/null 2>&1
    status="$?"

    assert_false "$status" "update should fail when tool name is missing"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m update_missing_tool_name passed"
}

test_update_tool_not_found() {
    local status=""

    echo "Testing update when tool is not installed..."
    cleanup_test_env
    setup_test_env

    bashlib_update_tool "$TOOL_NAME" > /dev/null 2>&1
    status="$?"

    assert_false "$status" "update should fail when tool is not found"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m update_tool_not_found passed"
}

test_update_missing_metadata() {
    local status=""

    echo "Testing update with missing tool metadata..."
    cleanup_test_env
    setup_test_env

    create_local_tool_bin

    bashlib_update_tool "$TOOL_NAME" > /dev/null 2>&1
    status="$?"

    assert_false "$status" "update should fail when tool.toml is missing"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m update_missing_metadata passed"
}

test_update_missing_repo() {
    local status=""

    echo "Testing update with missing repo key..."
    cleanup_test_env
    setup_test_env

    create_local_tool_bin
    create_tool_toml_without_repo

    bashlib_update_tool "$TOOL_NAME" > /dev/null 2>&1
    status="$?"

    assert_false "$status" "update should fail when project.repo is missing"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m update_missing_repo passed"
}

test_update_install_failure_propagates() {
    local status=""

    echo "Testing update when install-from-repo fails..."
    cleanup_test_env
    setup_test_env

    create_local_tool_bin
    create_tool_toml_with_repo "https://example.com/some/tool.git"

    (
        bashlib_install_from_repo() { return 55; }
        bashlib_update_tool "$TOOL_NAME" > /dev/null 2>&1
    )
    status="$?"

    assert_false "$status" "update should fail when install-from-repo fails"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m update_install_failure_propagates passed"
}

test_update_no_unexpected_stdout() {
    echo "Testing update has no unexpected stdout leaks..."

    local out=""

    cleanup_test_env
    setup_test_env

    create_local_tool_bin
    create_tool_toml_with_repo "https://example.com/some/tool.git"

    out="$(
        bashlib_install_from_repo() { return 1; }
        bashlib_update_tool "$TOOL_NAME" 2>/dev/null
    )"
    assert_str_eq "$out" "" "update should not print raw prefix/output to stdout"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m update_no_unexpected_stdout passed"
}

test_update_prefix_consistency() {
    echo "Testing update prefix consistency..."

    local status=""

    (
        _bashlib_update_find_prefix() { printf "%s\n" "/usr"; return 0; }
        bashlib_install_from_repo() { return 0; }

        # Expected after fix:
        # - either update fails early with unsupported prefix
        # - or update supports /usr and succeeds
        bashlib_update_tool "$TOOL_NAME" > /dev/null 2>&1
    )
    status="$?"

    # Choose one assertion based on chosen fix strategy.
    # If /usr is removed/unsupported:
    assert_false "$status" "update should not proceed with unsupported /usr prefix"

    echo -e "\e[1;32m[TEST]:\e[0m update_prefix_consistency passed"
}

test_lib_update_main() {
    echo -e "\e[1;36m[TEST]:\e[0m Running update tests..."

    test_find_prefix_local
    test_update_missing_tool_name
    test_update_tool_not_found
    test_update_no_unexpected_stdout
    test_update_prefix_consistency
    test_update_missing_metadata
    test_update_missing_repo
    test_update_install_failure_propagates

    echo -e "\e[1;32m[TEST]:\e[0m All update tests passed!!!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    test_lib_update_main "$@"
fi