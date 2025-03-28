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

.PHONY: help install_i3

install_i3:
	@echo "Installing i3 window manager and dependencies..."
	sudo apt-get update
	sudo apt-get install -y i3 i3status i3lock dmenu
	sudo apt-get install -y alacritty
	sudo apt-get install -y feh picom rofi dunst
	sudo apt-get install -y xbacklight pulseaudio pavucontrol
	@echo "i3 and dependencies installed successfully."
