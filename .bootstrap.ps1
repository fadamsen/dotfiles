# Enable Developer Mode in Windows before proceeding:
# https://learn.microsoft.com/en-us/windows/advanced-settings/developer-mode

# Install scoop and chezmoi
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install chezmoi

# Install essential WinGet packages
$winGetPackages = @(
  "Git.Git"
  "Microsoft.PowerShell"
)

winget install --no-upgrade --accept-package-agreements --accept-source-agreements --exact @winGetPackages

# Install C++ build tools
winget install --no-upgrade --accept-package-agreements --accept-source-agreements --exact --id `
  Microsoft.VisualStudio.2022.Community --override `
  "--quiet --wait --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --addProductLang En-us"

# Set persistent environment variables
$env:ESPANSO_CONFIG_DIR = "$HOME\.config\espanso"
[Environment]::SetEnvironmentVariable('ESPANSO_CONFIG_DIR', $env:ESPANSO_CONFIG_DIR, 'User')

$env:JJ_CONFIG = "$HOME\.config\jj\config.toml"
[Environment]::SetEnvironmentVariable('JJ_CONFIG', $env:JJ_CONFIG, 'User')

# Create junctions
New-Item `
    -ItemType Junction `
    -Path (Join-Path $env:ESPANSO_CONFIG_DIR 'match') `
    -Target (Join-Path $env:OneDrive 'Documents\Espanso')
