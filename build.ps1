param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

# Remove the 'v' from the version number if its present
$version = $version -replace "v", ""

$manifestParams = @{
    "ModuleVersion"        = $version
    "Path"                 = "./ps-arch-wsl/ps-arch-wsl.psd1"
    "Author"               = "Scott McKendry"
    "CompanyName"          = "www.scottmckendry.tech"
    "RootModule"           = "ps-arch-wsl.psm1"
    "CompatiblePSEditions" = @("Desktop", "Core")
    "FunctionsToExport"    = @("Install-ArchWSL", "Uninstall-ArchWSL")
    "Description"          = "Install Arch Linux on Windows the easy way."
    "ProjectUri"           = "https://github.com/scottmckendry/ps-arch-wsl"
    "LicenseUri"           = "https://github.com/scottmckendry/ps-arch-wsl/blob/main/LICENSE"
    "PowerShellVersion"    = "5.1"
    "PassThru"             = $true
}

# Copy the README.md file to the module directory
Copy-Item -Path "./README.md" -Destination "./ps-arch-wsl/README.md" -Force -ErrorAction SilentlyContinue

# Create the module manifest
Remove-Item -Path "./ps-arch-wsl/ps-arch-wsl.psd1" -Force -ErrorAction SilentlyContinue
New-ModuleManifest @manifestParams
