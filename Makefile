# Main Makefile
include make/*.mk

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  install_omz          - Install ZSH, Oh My Zsh, and plugins"
	@echo "  install_yazi         - Install Yazi file manager"
	@echo "  install_zellij       - Install Zellij terminal multiplexer"
	@echo "  install_dependencies - Install system dependencies"
	@echo "  install_i3           - Install i3 window manager and dependencies"
	@echo "  install_htop_vim     - Install htop with vim bindings"

.PHONY: help install_i3

install_i3:
	@echo "Installing i3 window manager and dependencies..."
	sudo apt-get update
	sudo apt-get install -y i3 i3status i3lock dmenu
	sudo apt-get install -y alacritty
	sudo apt-get install -y pulsemixer
	sudo apt-get install -y feh picom rofi dunst
	sudo apt-get install -y xbacklight pulseaudio pavucontrol
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
	