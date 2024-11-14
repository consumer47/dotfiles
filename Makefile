.PHONY: install_omz install_zsh

install_dependencies:
	apt install -y stow curl zsh 

install_omz: install_dependencies install_zsh
	@echo "Installing Oh My Zsh..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

	@echo "Installing necessary plugins..."
	@git clone https://github.com/zsh-users/zsh-autosuggestions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already installed"
	@git clone https://github.com/zsh-users/zsh-syntax-highlighting $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already installed"
	@git clone https://github.com/zsh-users/zsh-completions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions already installed"

	@echo "Installation complete. Remember to add plugins to your .zshrc."

install_zsh:
	stow -v zsh


