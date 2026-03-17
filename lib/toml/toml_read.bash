#!/usr/bin/env bash

if [[  -v TOML_READ_SOURCED ]]; then return 0; fi
TOML_READ_SOURCED=1

TOML_READ_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$TOML_READ_DIR/toml_check.bash"
source "$TOML_READ_DIR/toml_err.bash"


# toml_read_file <file>
# reads a toml file and sends it to stdout to be captured.
# does not clean out comments or change format.
toml_read_file() {
    local file="$1" status=""
    toml_check_file "$file"
    status="$?"
    if [ "$status" -ne "$TOML_SUCCESS" ]; then
	toml_error "Invalid toml file"
	return "$TOML_NO_FILE"
    fi

    # Read out the full file
    cat "$file"   
    return 0
}

# toml_read_table <file> <table>
# reads out the given table and all its entries to stdout
toml_read_table () {
    # Check the number of arguments.
    toml_check_arg_count "$#" 2 || {
        toml_error "toml_read_table: Invalid argument count $#/3"
        return "$TOML_INVALID_ARGS"
    }
    
    # declare vars
    local file="$1" table="$2" status=""

    # Check file
    toml_check_file "$file"
    status="$?"
    if [ "$status" -ne "$TOML_SUCCESS" ]; then
	toml_error "Invalid toml file"
	return "$TOML_NO_FILE"
    fi

    # Check table
    toml_check_table "$file" "$table"
    status="$?"
    if [ "$status" -ne "$TOML_SUCCESS" ]; then
	toml_error "Table Not found"
	return "$TOML_NO_TABLE"
    fi

    # Readout the whole table to stdout for capture
    awk -v table="$table" '
        BEGIN {
            in_table = 0
            found = 0
        }

        # entering any table header
        /^[[:space:]]*\[/ {
            if (in_table) exit 0
            in_table = 0
        }

        # target table header
        $0 ~ "^[[:space:]]*\\[" table "\\][[:space:]]*$" {
            in_table = 1
            found = 1
            next
        }

        # while in table, skip blank lines and pure comments
        in_table && /^[[:space:]]*$/ { next }
        in_table && /^[[:space:]]*#/ { next }

        # print key/value pairs
        in_table && /^[[:space:]]*[^#][^=]*=[[:space:]]*/ {
            line = $0

            # split key from value
            key = line
            sub(/=.*/, "", key)
            sub(/^[[:space:]]+/, "", key)
            sub(/[[:space:]]+$/, "", key)

            value = line
            sub(/^[^=]+=[[:space:]]*/, "", value)
            sub(/[[:space:]]+#.*$/, "", value)
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)

            if (value ~ /^".*"$/) {
                sub(/^"/, "", value)
                sub(/"$/, "", value)
            }

            printf "%s\t%s\n", key, value
        }

        END {
            if (!found) exit 1
        }
    ' "$file"

    status="$?"
    if [ "$status" -eq 0 ]; then
        return "$TOML_SUCCESS"
    fi

    toml_error "Table Not Found"
    return "$TOML_NO_TABLE"
}

# toml_read_key <file> <table> <key>
# reads the desired key's value to stdout for capture
toml_read_key() {
    toml_check_arg_count "$#" 3 || {
        toml_error "toml_read_key: Invalid argument count $#/3"
        return "$TOML_INVALID_ARGS"
    }

    local file="$1" table="$2" key="$3" status=""

    toml_check_file "$file"
    status="$?"
    if [ "$status" -ne "$TOML_SUCCESS" ]; then
        toml_error "Invalid toml file"
        return "$TOML_NO_FILE"
    fi

    toml_check_table "$file" "$table"
    status="$?"
    if [ "$status" -ne "$TOML_SUCCESS" ]; then
        toml_error "Table Not found"
        return "$TOML_NO_TABLE"
    fi

    awk -v table="$table" -v key="$key" '
        BEGIN {
            in_table = 0
            found = 0
        }

        /^[[:space:]]*\[/ {
            in_table = 0
        }

        $0 ~ "^[[:space:]]*\\[" table "\\][[:space:]]*$" {
            in_table = 1
            next
        }

        in_table && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
            line = $0
            sub(/^[[:space:]]*[^=]+=[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+$/, "", line)

            if (line ~ /^".*"$/) {
                sub(/^"/, "", line)
                sub(/"$/, "", line)
            }

            print line
            found = 1
            exit
        }

        END {
            if (!found) exit 1
        }
    ' "$file"

    status="$?"
    if [ "$status" -eq 0 ]; then
        return "$TOML_SUCCESS"
    fi

    toml_error "Key Not Found"
    return "$TOML_READ_FAILED"
}
