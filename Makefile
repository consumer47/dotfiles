.PHONY: install_omz install_zsh

install_dependencies:
	apt install -y stow curl zsh 

install_zsh:
	stow -v zsh

install_omz: install_dependencies install_zsh
	@echo "Installing Oh My Zsh..."
	cd && sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended && \
	git clone https://github.com/zsh-users/zsh-autosuggestions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already installed" && \
	git clone https://github.com/zsh-users/zsh-syntax-highlighting $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already installed" && \
	git clone https://github.com/zsh-users/zsh-completions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions already installed" && \
	git clone https://github.com/jeffreytse/zsh-vi-mode  $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode || echo "zsh-vi-mode  already installed" && \
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
	@echo "Installation complete. Remember to add plugins to your .zshrc."



