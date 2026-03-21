# API Reference

This file documents only the CLI and sourceable library API for `bashlib-installer`.

## CLI

`installer` is a dispatcher command:

```bash
installer <command> [args]
```

Available commands:

```bash
installer help
installer install --help
installer remove --help
installer update --help
installer create --help
```

### `installer install`

Install a project from a local path or from a repository URL.

Usage:

```bash
installer install [options] <path>
```

Options:

- `-g`, `--global`: install to `/usr/local` instead of `$HOME/.local`.
- `--repo`: treat `<path>` as a repo URL and install from a clone.
- `--help`: print command help.

Examples:

```bash
installer install ./my-tool
installer install --global ./my-tool
installer install --repo "https://github.com/user/my-tool.git"
installer install --global --repo "https://github.com/user/my-tool.git"
```

### `installer remove`

Remove an installed tool by name.

Usage:

```bash
installer remove <project-name>
```

Options:

- `--help`: print command help.

Examples:

```bash
installer remove installer
installer remove my-tool
```

### `installer update`

Update an installed tool using the `repo` value from its installed `tool.toml`.

Usage:

```bash
installer update <tool-name>
```

Options:

- `--help`: print command help.

Example:

```bash
installer update installer
```


## Sourceable API

After installation, source the library from one of these paths:

```bash
if [[ -f "${HOME}/.local/lib/installer/bashlib_installer.bash" ]]; then
	source "${HOME}/.local/lib/installer/bashlib_installer.bash"
elif [[ -f "/usr/local/lib/installer/bashlib_installer.bash" ]]; then
	source "/usr/local/lib/installer/bashlib_installer.bash"
else
	echo "installer library not found" >&2
	exit 1
fi
```

### Exported functions

`bashlib_install_from_source <source_dir> <install_prefix> [debug_level]`

- Installs from a local project directory.
- `install_prefix` must be `$HOME/.local` or `/usr/local`.

`bashlib_install_from_repo <repo_url> <install_prefix> [debug_level]`

- Clones repo to a temporary directory, then installs it.

`bashlib_install_dependencies <source_dir> <install_prefix> [debug_level]`

- Reads `[dependencies]` from `tool.toml` and installs missing deps.

`bashlib_update_tool <tool_name>`

- Finds installed tool metadata and updates from configured repo.

`bashlib_remove_tool <tool_name>`

- Removes installed files/directories for the tool from standard locations.

### API usage examples

Local source install:

```bash
bashlib_install_from_source "./my-tool" "$HOME/.local" 0
```

Repo install:

```bash
bashlib_install_from_repo "https://github.com/user/my-tool.git" "$HOME/.local" 0
```

Update and remove:

```bash
bashlib_update_tool "my-tool"
bashlib_remove_tool "my-tool"
```

### Expected project shape for installs

```text
project/
  <tool>
  tool.toml
  lib/
  libexec/
```
