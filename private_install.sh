# Default tools ------------------------------------------------------------------------------------------
sudo apt-get install -y direnv curl build-essential git gh zoxide tldr gnome-tweaks apt-transport-https ca-certificates software-properties-common
tldr update

# Install default tools for my personal .bashrc ----------------------------------------------------------
sudo snap install kubectl --classic
# Cargo
curl https://sh.rustup.rs -sSf | sh
# Starship
curl -sS https://starship.rs/install.sh | sh

# Dot files ----------------------------------------------------------------------------------------------
sudo snap install chezmoi --classic
chezmoi init https://gitlab.com/jmyl/dotfiles.git
chezmoi apply

# Browser ------------------------------------------------------------------------------------------------
sudo snap install brave
# - Enable sync
# - Increase default font size

# Install cuda toolkit -----------------------------------------------------------------------------------
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-13-0#

# Install nvidia driver ----------------------------------------------------------------------------------
sudo apt-get install -y nvidia-open

# Install regolith-desktop -------------------------------------------------------------------------------
wget -qO - https://archive.regolith-desktop.com/regolith.key | gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg >/dev/null
echo deb "[arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] \
https://archive.regolith-desktop.com/ubuntu/stable noble v3.3" | sudo tee /etc/apt/sources.list.d/regolith.list
sudo apt-get update
sudo apt-get install -y regolith-desktop regolith-session-flashback regolith-look-dracula
sudo apt-get remove regolith-wm-base-launchers regolith-i3-ilia regolith-wm-navigation regolith-i3-session
# Use i3 as a default session
ls /usr/share/xsessions
sudo nvim /var/lib/AccountsService/users/sungsik
sudo apt install maim

# Setup ssh ----------------------------------------------------------------------------------------------
sudo apt-get install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status

# For Neovim Plugins -------------------------------------------------------------------------------------
sudo apt-get install -y imagemagick xclip
sudo apt-get install -y libmagickwand-dev
# Latex Tools
sudo apt-get install -y pandoc texlive-latex-base texlive-latex-extra texlive-fonts-extra texlive-bibtex-extra texlive-latex-recommended
sudo apt-get install -y ripgrep fd-find clang ccache doxygen lcov clang-tidy
sudo snap install cmake --classic
sudo apt-get install -y luarocks python3-venv python3-setuptools python3-dev
# Nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm ls-remote
nvm install 22.20.0
# Tree-sitter
cargo install tree-sitter-cli
sudo snap install nvim --classic

# vifm and related tools ---------------------------------------------------------------------------------
sudo apt-get install -y vifm zathura zathura-pdf-poppler atool aerc
# Install vimiv
curl
curl -L https://github.com/karlch/vimiv/archive/refs/tags/v0.9.1.tar.gz -o /tmp/vimiv.tar.gz
tar -xzf /tmp/vimiv.tar.gz -C /tmp
cd /tmp/$(tar -tzf /tmp/source.tar.gz | head -1 | cut -f1 -d"/")
sudo make install

# Kitty Terminal -----------------------------------------------------------------------------------------
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $HOME/.local/kitty.app/bin/kitty 50

# Opencode -----------------------------------------------------------------------------------------------
npm i -g opencode-ai@latest
opencode auth login

# Setup nixpkgs and flake --------------------------------------------------------------------------------
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

sudo apt-get install -y linux-tools-6.14.0-33-generic linux-cloud-tools-6.14.0-33-generic

# Install Docker & nvidia-container-toolkit
