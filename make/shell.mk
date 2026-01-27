install_dependencies:
	@echo "Installing dependencies... Please run as root."
	# Check if the script is running as root
ifeq ("$(shell whoami)", "root")
	apt-get update && apt-get install -y stow curl zsh
else
	sudo apt-get update && apt-get install -y stow curl zsh
	@echo "Not running as root."
endif

install_zsh:
	@stow -v zsh

install_commonrc:
	@stow -v commonrc

user_installations:
	@echo "Installing zsh plugins individually..."
	@mkdir -p ~/.zsh/plugins
	@git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions 2>/dev/null || echo "zsh-autosuggestions already installed"
	@git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting 2>/dev/null || echo "zsh-syntax-highlighting already installed"
	@git clone --depth=1 https://github.com/TunaCuma/zsh-vi-man ~/.zsh/plugins/zsh-vi-man 2>/dev/null || echo "zsh-vi-man already installed"
	@git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k 2>/dev/null || echo "powerlevel10k already installed"
	@curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || echo "zoxide installation skipped (may already be installed)"
	@git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || echo "fzf already installed"
	@~/.fzf/install --bin 2>/dev/null || echo "fzf installation skipped (may already be installed)"
	@echo "Installation complete. Plugins are installed to ~/.zsh/plugins/"

install_zsh_plugins: install_zsh install_commonrc user_installations

.PHONY: install_dependencies install_zsh install_commonrc user_installations install_zsh_plugins 