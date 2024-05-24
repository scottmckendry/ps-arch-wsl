A simple PowerShell module to aid in the installation of Arch Linux on Windows Subsystem for Linux (WSL).

Uses the pre-built distribution available from [yuk7's GitHub](https://github.com/yuk7/ArchWSL).

Automates the installation process by:

-   Installing yuk7's signing key to the local machine's trusted keys.
-   Downloads and installs the appx package from the latest release.
-   Initialises the pacman keyring and updates the system.
-   Installs the `git` and `base-devel` packages.
-   Optionally creates a new user account and sets the password (Using a `PSCredential` object).
-   Optionally runs a post-install script to perform any additional configuration.

## 📦 Installation

```powershell
Install-Module -Name ps-arch-wsl
```

## 🚀 Usage

Install with the default configuration (`root` user account only, no post-install script):

```powershell
# Must be run as an administrator
Install-ArchWSL
```

Uninstall:

```powershell
Uninstall-ArchWSL
```

## 🧙‍♂️ Advanced Usage

Install with a custom user account and post-install script:

> [!TIP]
> The post-install script must be a relative path to the script file from the current working directory.

```bash
#!/bin/bash
# post-install.sh
cd ~
mkdir git && cd git
git clone https://github.com/scottmckendry/dots && cd dots
./setup.sh
```

```powershell
#requires -RunAsAdministrator
$Credential = Get-Credential -UserName "scott"
Install-ArchWSL -Credential $Credential -PostInstallScript "./post-install.sh"
```
