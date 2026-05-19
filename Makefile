# Main Makefile
include make/*.mk

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  install_zsh_plugins   - Install ZSH and plugins (without Oh My Zsh)"
	@echo "  install_yazi         - Install Yazi file manager"
	@echo "  install_zellij       - Install Zellij terminal multiplexer"
	@echo "  install_dependencies - Install system dependencies"
	@echo "  install_i3           - Install i3 window manager and dependencies"
	@echo "  install_htop_vim     - Install htop with vim bindings"
	@echo "  install_scrcpy       - Install scrcpy and adb for Android mirroring"
	@echo "  install_tmux         - Stow tmux and urlview config, run TPM plugin installer"
	@echo "  install_taskwarrior_tui - Install taskwarrior-tui (.deb, sudo) for leader key + Alacritty"
	@echo "  install_taskwarrior_tui_cargo - Same via cargo (no sudo, needs rust)"

.PHONY: help install_i3 install_scrcpy install_tmux install_taskwarrior_tui install_taskwarrior_tui_cargo

DOTFILES_DIR := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

install_tmux:
	@echo "Installing tmux config and urlview (symlinks)..."
	@cd "$(DOTFILES_DIR)" && stow -v tmux && stow -v urlview
	@echo "Installing TPM and plugins..."
	@cd "$(DOTFILES_DIR)" && ./install_tmux_plugins.sh
	@echo "tmux setup done. Restart tmux to load config and plugins."

install_i3:
	@echo "Installing i3 window manager and dependencies..."
	@if [ -f /etc/arch-release ]; then \
		sudo pacman -Sy --noconfirm i3-wm i3status i3lock dmenu; \
		sudo pacman -Sy --noconfirm alacritty; \
		sudo pacman -Sy --noconfirm pulsemixer; \
		sudo pacman -Sy --noconfirm feh picom rofi dunst; \
		sudo pacman -Sy --noconfirm light pulseaudio pavucontrol; \
	elif [ -f /etc/debian_version ]; then \
		sudo apt-get update; \
		sudo apt-get install -y i3 i3status i3lock dmenu; \
		sudo apt-get install -y alacritty; \
		sudo apt-get install -y pulsemixer; \
		sudo apt-get install -y feh picom rofi dunst; \
		sudo apt-get install -y xbacklight pulseaudio pavucontrol; \
	else \
		echo "Unsupported OS. Please install i3 and dependencies manually."; \
		exit 1; \
	fi
	@echo "i3 and dependencies installed successfully."

install_htop_vim:
	@echo "Installing htop with vim bindings..."
	# Detect OS and install dependencies
	if [ -f /etc/debian_version ]; then \
		sudo apt-get update; \
		sudo apt-get install -y libncursesw5-dev autotools-dev autoconf automake build-essential; \
	elif [ -f /etc/arch-release ]; then \
		sudo pacman -S --noconfirm ncurses automake autoconf gcc; \
	else \
		echo "Unsupported OS. Please install dependencies manually."; \
		exit 1; \
	fi
	# Clone the repository
	git clone https://github.com/KoffeinFlummi/htop-vim.git /tmp/htop
	# Build and install
	cd /tmp/htop && ./autogen.sh && ./configure && make
	cd /tmp/htop && sudo make install
	@echo "htop with vim bindings installed successfully."

install_taskwarrior_tui:
	@chmod +x "$(DOTFILES_DIR)/scripts/install-taskwarrior-tui-deb.sh" \
		"$(DOTFILES_DIR)/i3/.config/i3/taskwarrior-tui-launch.sh"
	@bash "$(DOTFILES_DIR)/scripts/install-taskwarrior-tui-deb.sh"

install_taskwarrior_tui_cargo:
	@chmod +x "$(DOTFILES_DIR)/scripts/install-taskwarrior-tui-deb.sh" \
		"$(DOTFILES_DIR)/i3/.config/i3/taskwarrior-tui-launch.sh"
	@bash "$(DOTFILES_DIR)/scripts/install-taskwarrior-tui-deb.sh" cargo

install_scrcpy:
	@echo "Installing scrcpy and adb..."
	@if [ -f /etc/arch-release ]; then \
		sudo pacman -Sy --noconfirm scrcpy android-tools; \
	elif [ -f /etc/debian_version ]; then \
		sudo apt-get update; \
		sudo apt-get install -y scrcpy adb; \
	else \
		echo "Unsupported OS. Please install scrcpy and adb manually."; \
		exit 1; \
	fi
	@echo "scrcpy and adb installed successfully."
