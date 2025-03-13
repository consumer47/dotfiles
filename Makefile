# Main Makefile
include make/*.mk

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  install_omz          - Install ZSH, Oh My Zsh, and plugins"
	@echo "  install_yazi         - Install Yazi file manager"
	@echo "  install_zellij       - Install Zellij terminal multiplexer"
	@echo "  install_dependencies - Install system dependencies"

.PHONY: help
