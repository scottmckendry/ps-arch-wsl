param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$manifestParams = @{
    "ModuleVersion"        = $version
    "Path"                 = "./ps-arch-wsl/ps-arch-wsl.psd1"
    "Author"               = "Scott McKendry"
    "CompanyName"          = "www.scottmckendry.tech"
    "RootModule"           = "ps-arch-wsl.psm1"
    "CompatiblePSEditions" = @("Desktop", "Core")
    "FunctionsToExport"    = @("Install-ArchWSL", "Uinstall-ArchWSL")
    "Description"          = "Install Arch Linux on Windows the easy way."
    "ProjectUri"           = "https://github.com/scottmckendry/ps-arch-wsl"
    "LicenseUri"           = "https://github.com/scottmckendry/ps-arch-wsl/blob/main/LICENSE"
    "PowerShellVersion"    = "5.1"
    "PassThru"             = $true
}

Copy-Item -Path "./README.md" -Destination "./ps-arch-wsl/README.md" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "./ps-arch-wsl/ps-arch-wsl.psd1" -Force -ErrorAction SilentlyContinue
New-ModuleManifest @manifestParams
