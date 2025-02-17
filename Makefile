.PHONY: install_omz install_zsh install_dependencies user_installations

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

install_zellij:
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	cargo install --locked zellij
	@stow zellij


install_commonrc:
		@stow -v commonrc

user_installations:
		@echo "Installing Oh My Zsh and plugins..."
		cd && sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended && \
		git clone https://github.com/zsh-users/zsh-autosuggestions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already installed" && \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already installed" && \
		git clone https://github.com/zsh-users/zsh-completions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions already installed" && \
		git clone https://github.com/jeffreytse/zsh-vi-mode  $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode || echo "zsh-vi-mode  already installed" && \
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
		git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
		~/.fzf/install --bin # bin argument should prevent interactive prompt and wont change rc files
		@echo "Installation complete. Remember to add plugins to your .zshrc."

install_omz:  install_zsh install_commonrc user_installations
