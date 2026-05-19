#!/bin/bash
# Run on the Pi (e.g. via: ssh pi@192.168.178.120 'bash -s' < scripts/install-zsh-remote-pi.sh)
# Installs zsh, stows dotfiles, and installs plugins + Powerlevel10k.

set -e

echo "[1/5] Installing packages (if apt fails, Pi clock may be wrong: run 'sudo timedatectl set-ntp true')..."
sudo apt-get update || true
sudo apt-get install -y zsh stow git curl fzf || true

echo "[2/5] Deploying zsh config..."
cd ~/dotfiles
for f in .zshrc .zprofile .fzf.zsh; do
  [ -f ~/"$f" ] && [ ! -L ~/"$f" ] && mv -v ~/"$f" ~/"$f.bak"
done
if command -v stow &>/dev/null; then
  stow -v zsh
else
  echo "Stow not found, copying zsh files manually..."
  cp -v zsh/.zshrc zsh/.zprofile zsh/.fzf.zsh ~/
fi

echo "[3/5] Installing zsh plugins and Powerlevel10k..."
mkdir -p ~/.zsh/plugins
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions 2>/dev/null || echo "zsh-autosuggestions already installed"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting 2>/dev/null || echo "zsh-syntax-highlighting already installed"
git clone --depth=1 https://github.com/TunaCuma/zsh-vi-man ~/.zsh/plugins/zsh-vi-man 2>/dev/null || echo "zsh-vi-man already installed"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k 2>/dev/null || echo "powerlevel10k already installed"

echo "[4/5] Setting zsh as default shell..."
if chsh -s "$(command -v zsh)" 2>/dev/null; then
  echo "Default shell set to zsh."
else
  echo "chsh needs your password. Run manually: chsh -s \$(which zsh)"
fi

echo "[5/5] Done. Log out and back in (or open a new session) to use zsh. Run 'p10k configure' to customize the theme."
