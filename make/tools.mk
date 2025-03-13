# Architecture detection for Yazi
ARCH := $(shell uname -m)

ifeq ($(ARCH),x86_64)
    YAZI_ARCH = yazi-x86_64-unknown-linux-gnu.zip
else ifeq ($(ARCH),aarch64)
    YAZI_ARCH = yazi-aarch64-unknown-linux-gnu.zip
else
    $(error Unsupported architecture: $(ARCH))
endif

YAZI_URL = https://github.com/sxyazi/yazi/releases/latest/download/$(YAZI_ARCH)

install_yazi:
	@echo "Detected architecture: $(ARCH)"
	@echo "Downloading Yazi for $(ARCH)..."
	wget -qO yazi.zip $(YAZI_URL)
	@echo "Extracting Yazi..."
	unzip -q yazi.zip -d yazi-temp
	@echo "Installing Yazi to /usr/local/bin..."
	sudo mv yazi-temp/*/yazi /usr/local/bin
	@echo "Verifying installation..."
	yazi --version
	@echo "Cleaning up..."
	rm -rf yazi-temp yazi.zip
	@echo "Yazi installation completed successfully!"

install_zellij:
	@stow zellij
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	cargo install --locked zellij

.PHONY: install_yazi install_zellij 