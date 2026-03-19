# Install

This page is only for installing `bashlib-installer` onto your system using the tool itself.

## Local Install (recommended)

Installs to your user paths (`$HOME/.local/bin`, `$HOME/.local/lib`, `$HOME/.local/libexec`).

```bash
git clone "https://github.com/JMinyard1335/bashlib-installer.git"
cd bashlib-installer
chmod +x ./installer
./installer install .
```

## Global Install

Installs to system paths (`/usr/local/bin`, `/usr/local/lib`, `/usr/local/libexec`).
Requires root/sudo.

```bash
git clone "https://github.com/JMinyard1335/bashlib-installer.git"
cd bashlib-installer
chmod +x ./installer
sudo ./installer install --global .
```

## Verify

```bash
installer help
installer install --help
```

If `installer` is not found after local install, make sure `$HOME/.local/bin` is in your `PATH`.

