# Install prerequisite packages
sudo apt update
sudo apt install build-essential unzip

# Install PowerShell
sudo apt install wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -s -r)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell

# Install Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s

# Install Rust and crates
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install cargo-binstall

# Install chezmoi
sudo snap install chezmoi --classic
