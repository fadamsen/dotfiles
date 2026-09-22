# dotfiles
My personal dotfiles and workstation configuration, managed with
[chezmoi](https://www.chezmoi.io/).

The repository contains configuration and bootstrap tooling for my development
environments. It is primarily intended for my own use, but is public in case
parts of the setup are useful to others.

## Setup
Setup depends on your operating system, with Windows 11 and Ubuntu Linux being
supported.

### Windows 11
Enabling [Windows Developer Mode](https://learn.microsoft.com/en-us/windows/advanced-settings/developer-mode)
is recommended, primarily to support proper symlinks without requiring
elevation.

Then run the contents of [.bootstrap.ps1](.bootstrap.ps1), but *make sure* you
understand what you're doing before you do so. In particular, decide if you're
comfortable installing [scoop](https://scoop.sh) using `Invoke-Expression`.

### Ubuntu Linux
Run the contents of [.bootstrap.sh](.bootstrap.sh), but *make sure* you
understand what you're doing before you do so. In particular, decide if you're
comfortable installing Oh My Posh and Rust by piping into `bash`/`sh`,
respectively.

## Run chezmoi
Finally, once all prerequisites are in place, you can start using chezmoi:

```pwsh
chezmoi init --apply https://github.com/fadamsen/dotfiles.git
```

Enjoy!
