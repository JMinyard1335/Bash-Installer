#!/usr/bin/env bash
# Used to test remove library functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test_asserts.bash"
source "$SCRIPT_DIR/../lib/internal/bashlib_remove.bash"
source "$SCRIPT_DIR/../lib/internal/installer_format.bash"

# -----------------------------------------------------------------------------
# Test sandbox
# -----------------------------------------------------------------------------

TEST_ROOT=""
TOOL_NAME="mytool"

setup_test_env() {
	TEST_ROOT="$(mktemp -d)"
	mkdir -p "$TEST_ROOT/.local/bin"
	mkdir -p "$TEST_ROOT/.local/lib/$TOOL_NAME"
	mkdir -p "$TEST_ROOT/.local/libexec/$TOOL_NAME"
	touch "$TEST_ROOT/.local/bin/$TOOL_NAME"
	echo "dummy" > "$TEST_ROOT/.local/lib/$TOOL_NAME/helper.bash"
	echo "dummy" > "$TEST_ROOT/.local/libexec/$TOOL_NAME/subcmd"
}

cleanup_test_env() {
	[[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

assert_removed_file() {
	local path="$1" msg="${2:-Expected file to be removed: $1}"
	[[ ! -e "$path" ]] || assert_false 0 "$msg"
}

assert_removed_dir() {
	local path="$1" msg="${2:-Expected directory to be removed: $1}"
	[[ ! -d "$path" ]] || assert_false 0 "$msg"
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

test_remove_invalid_input() {
	echo "Testing remove with invalid input..."
	cleanup_test_env
	setup_test_env

	local status=""
	status=$(bashlib_remove_tool "" > /dev/null 2>&1)
	assert_false $? "remove_tool should fail on missing tool name"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m remove_invalid_input passed"
}


# Test removal with 'yes' input
# Test removal with 'yes' input for all prompts
test_remove_local_yes() {
	echo "Testing local removal with 'yes'..."
	cleanup_test_env
	setup_test_env

	export HOME="$TEST_ROOT"
	printf "y\ny\ny\n" | bashlib_remove_tool "$TOOL_NAME" > /dev/null 2>&1
	local status=$?

	assert_true $status "remove_tool should succeed with 'y' for all prompts"
	assert_removed_file "$HOME/.local/bin/$TOOL_NAME" "bin file should be removed (y)"
	assert_removed_dir "$HOME/.local/lib/$TOOL_NAME" "lib dir should be removed (y)"
	assert_removed_dir "$HOME/.local/libexec/$TOOL_NAME" "libexec dir should be removed (y)"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m remove_local_yes passed"
}

# Test removal with 'no' input for all prompts
test_remove_local_no() {
	echo "Testing local removal with 'no'..."
	cleanup_test_env
	setup_test_env

	export HOME="$TEST_ROOT"
	printf "n\nn\nn\n" | bashlib_remove_tool "$TOOL_NAME" > /dev/null 2>&1
	local status=$?

	assert_true $status "remove_tool should succeed with 'n' for all prompts"
	# Files should NOT be removed
	assert_exists "$HOME/.local/bin/$TOOL_NAME" "bin file should NOT be removed (n)"
	assert_directory "$HOME/.local/lib/$TOOL_NAME" "lib dir should NOT be removed (n)"
	assert_directory "$HOME/.local/libexec/$TOOL_NAME" "libexec dir should NOT be removed (n)"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m remove_local_no passed"
}

# Test removal with invalid input for all prompts
test_remove_local_invalid() {
	echo "Testing local removal with invalid input..."
	cleanup_test_env
	setup_test_env

	export HOME="$TEST_ROOT"
	printf "foo\nbar\nbaz\n" | bashlib_remove_tool "$TOOL_NAME" > /dev/null 2>&1
	local status=$?

	assert_true $status "remove_tool should succeed with invalid input for all prompts"
	# Files should NOT be removed
	assert_exists "$HOME/.local/bin/$TOOL_NAME" "bin file should NOT be removed (invalid)"
	assert_directory "$HOME/.local/lib/$TOOL_NAME" "lib dir should NOT be removed (invalid)"
	assert_directory "$HOME/.local/libexec/$TOOL_NAME" "libexec dir should NOT be removed (invalid)"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m remove_local_invalid passed"
}

test_remove_failure_propagates() {
    echo "Testing remove propagates deletion failures..."

    cleanup_test_env
    setup_test_env

    export HOME="$TEST_ROOT"

    (
        rm() { return 1; }
        printf "y\ny\ny\n" | bashlib_remove_tool "$TOOL_NAME" > /dev/null 2>&1
    )
    local status=$?

    assert_false "$status" "remove_tool should fail when rm fails"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m remove_failure_propagates passed"
}

test_lib_remove_main() {
	echo -e "\e[1;36m[TEST]:\e[0m Running remove tests..."

	test_remove_invalid_input
	test_remove_local_yes
	test_remove_local_no
	test_remove_failure_propagates
	test_remove_local_invalid

	echo -e "\e[1;32m[TEST]:\e[0m All remove tests passed!!!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	test_lib_remove_main "$@"
fi

