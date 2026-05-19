#!/usr/bin/env bash
# Install taskwarrior-tui (Rust TUI). https://github.com/kdheepak/taskwarrior-tui
#
#   make install_taskwarrior_tui                    # recommended (fixes chmod + runs with bash)
#   bash scripts/install-taskwarrior-tui-deb.sh     # if not executable: use bash, not ./
#   ./scripts/install-taskwarrior-tui-deb.sh        # needs chmod +x
#   ./scripts/install-taskwarrior-tui-deb.sh cargo  # ~/.cargo/bin (no sudo)
#
# After cargo install, your shell needs ~/.cargo/bin on PATH (see zsh/.zshrc).
set -euo pipefail
VERSION="${TASKWARRIOR_TUI_VERSION:-0.26.10}"

install_cargo() {
  command -v cargo >/dev/null 2>&1 || {
    echo "Install Rust first: https://rustup.rs/  (or: sudo apt install cargo)" >&2
    exit 1
  }
  cargo install taskwarrior-tui --locked
}

install_deb() {
  local deb="/tmp/taskwarrior-tui_${VERSION}.deb"
  curl -fsSL -o "$deb" \
    "https://github.com/kdheepak/taskwarrior-tui/releases/download/v${VERSION}/taskwarrior-tui.deb"
  sudo dpkg -i "$deb" || sudo apt-get install -f -y
  echo "You can remove $deb when done."
}

case "${1:-deb}" in
  cargo) install_cargo ;;
  deb|"") install_deb ;;
  *)
    echo "usage: $0 [deb|cargo]" >&2
    exit 1
    ;;
esac

command -v taskwarrior-tui
taskwarrior-tui --version
