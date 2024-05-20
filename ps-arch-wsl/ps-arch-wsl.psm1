function Get-WSLInstallStatus {
    <#
    .SYNOPSIS
        Checks if WSL is installed on the system.
    #>

    $wsl = wsl.exe --status
    if (!$wsl) {
        return $false
    }
    else {
        return $true
    }
}

function Convert-LineEndings {
    <#
    .SYNOPSIS
        Converts the line endings of a file to LF. This is useful when running scripts in WSL.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Check if the file exists
    if (!(Test-Path $Path)) {
        throw "Failed to convert line endings: File not found at $Path."
        return
    }

    $content = Get-Content -Path $Path -Raw
    $content = $content -replace "`r`n", "`n"
    Set-Content -Path $Path -Value $content -NoNewline
}

function Get-ReleaseAsset {
    <#
    .SYNOPSIS
        Downloads the latest version of an asset attached to a GitHub release and returns the path to the downloaded file in the temp directory.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        [Parameter(Mandatory = $true)]
        [string]$AssetFilter
    )

    try {
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest"
    }
    catch {
        throw "$Repository doesn't exist or has no releases."
        return
    }
    $destination = $null

    foreach ($asset in $releaseInfo.assets) {
        if ($asset.name -like "*$AssetFilter") {
            # Clean up the destination path
            $destination = "$env:TEMP\$($asset.name)"
            Write-Verbose "Destination: $destination"
            break
        }
    }

    if (!$destination) {
        throw "Failed to find an asset matching the filter '$AssetFilter' from the latest release of $Repository."
    }

    if (Test-Path $destination) {
        Remove-Item $destination -Force
    }

    $url = $asset.browser_download_url
    Write-Verbose "Downloading asset from $url"
    Invoke-WebRequest -Uri $url -OutFile $destination | Out-Null
    if (Test-Path $destination) {
        Write-Verbose "Asset downloaded successfully."
        return $destination
        break
    }
    else {
        throw "Failed to download an asset matching the filter '$AssetFilter' from the latest release of $Repository."
    }
}


function Install-ArchCertificate {
    <#
    .SYNOPSIS
        Installs the latest ArchWSL certificate into the users "Trusted People" store.
    #>

    $certificate = Get-ReleaseAsset -Repository "yuk7/ArchWSL" -AssetFilter "cer"
    if ($certificate) {
        try {
            $installed = Import-Certificate -FilePath $certificate -CertStoreLocation Cert:\LocalMachine\TrustedPeople
        }
        catch {
            throw "Failed to install the ArchWSL certificate: $_"
            return
        }

        if ($installed) {
            Write-Output "Successfully installed the ArchWSL certificate."
        }
    }
    else {
        throw "Failed to install the ArchWSL certificate: Certificate not found."
    }
}

function Invoke-ArchScript {
    <#
    .SYNOPSIS
        Invokes a script in the ArchWSL distribution.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Script
    )

    if (!(Get-WSLInstallStatus)) {
        throw "Failed to invoke script: WSL is not installed. Run 'wsl --install', restart your system and try again."
        return
    }

    try {
        wsl.exe --distribution arch --exec /bin/bash -c $Script
    }
    catch {
        throw "Failed to invoke script: $_"
    }
}

function Install-ArchWSL {
    <#
    .SYNOPSIS
        Installs the latest appx package of ArchWSL.
    #>

    param (
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $false)]
        [string]$PostInstallScript
    )

    if (!(Get-WSLInstallStatus)) {
        throw "Failed to update ArchWSL: WSL is not installed. Run 'wsl --install', restart your system and try again."
        return
    }

    $appx = Get-ReleaseAsset -Repository "yuk7/ArchWSL" -AssetFilter "appx"

    if ($appx) {
        try {
            Add-AppxPackage -Path $appx -ForceApplicationShutdown
        }
        catch {
            throw "Failed to install ArchWSL: $_"
            return
        }
    }
    else {
        throw "Failed to install ArchWSL: Appx package not found."
    }

    Write-Verbose "Registering ArchWSL distribution."
    Write-Output "" | arch

    Write-Verbose "Setting up keyring."
    try {
        Invoke-ArchScript -Script "pacman-key --init && pacman-key --populate archlinux && pacman -Syu --noconfirm archlinux-keyring"
    }
    catch {
        throw "Failed to set up keyring: $_"
        return
    }

    Write-Verbose "Installing pacman dependencies."
    try {
        Invoke-ArchScript -Script "pacman -Syu --noconfirm git base-devel"
    }
    catch {
        throw "Failed to install pacman dependencies: $_"
    }
    Clear-Host

    if ($Credential) {
        Write-Verbose "Creating ArchWSL user."
        New-ArchUser -Credential $Credential
    }

    Write-Output "Successfully installed ArchWSL."

    if ($PostInstallScript) {
        try {
            Convert-LineEndings -Path $PostInstallScript
        }
        catch {
            throw "Failed to invoke post-install script: $_"
        }
        Convert-LineEndings -Path $PostInstallScript
        try {
            wsl.exe --distribution arch -e $PostInstallScript
        }
        catch {
            throw "Failed to invoke post-install script: $_"
        }
    }
}

function Uninstall-ArchWSL {
    <#
    .SYNOPSIS
        Uninstalls ArchWSL.
    #>

    Write-Verbose "Checking for existing ArchWSL distribution."
    wsl.exe --unregister arch | Out-Null

    try {
        Get-AppxPackage -Name "yuk7.archwsl" | Remove-AppxPackage
    }
    catch {
        throw "Failed to uninstall ArchWSL: $_"
    }

    Write-Output "Successfully uninstalled ArchWSL."
}

function New-ArchUser {
    <#
    .SYNOPSIS
        Creates a new user in the ArchWSL distribution.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )

    try {
        Invoke-ArchScript "echo `"%wheel ALL=(ALL) ALL`" > /etc/sudoers.d/wheel && useradd -m -G wheel $($Credential.GetNetworkCredential().UserName) && echo `"$($Credential.GetNetworkCredential().Password)`" | passwd $($Credential.GetNetworkCredential().UserName) --stdin"
    }
    catch {
        throw "Failed to create user $($Credential.GetNetworkCredential().UserName): $_"
    }

    # Set the newly created user as the default login
    try {
        arch config --default-user $($Credential.GetNetworkCredential().UserName)
    }
    catch {
        throw "Failed to set default user: $_"
    }
}

Export-ModuleMember -Function Install-ArchWSL, Uninstall-ArchWSL
