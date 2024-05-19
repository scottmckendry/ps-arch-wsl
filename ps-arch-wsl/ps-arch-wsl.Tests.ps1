BeforeAll {
    Import-Module $PSScriptRoot/ps-arch-wsl.psm1 -Force
}

Describe "Get-ReleaseAsset" {
    It "Finds the release asset" {
        InModuleScope ps-arch-wsl {
            $foundAsset = Get-ReleaseAsset -Repository "yuk7/ArchWSL" -AssetFilter "cer"
            $latestCertificateInTemp = Get-ChildItem $env:Temp | Where-Object { $_.FullName -like "*.cer" } | Sort-Object -Property CreationTime -Descending
            $foundAsset | Should -Be $latestCertificateInTemp[0].FullName
        }
    }

    It "Can't find the release asset" {
        InModuleScope ps-arch-wsl {
            $repository = "yuk7/ArchWSL"
            $filter = "someNonExistentExt"
            { Get-ReleaseAsset -Repository $repository -AssetFilter $filter } | Should -Throw -ExpectedMessage "Failed to find an asset matching the filter '$filter' from the latest release of $repository."
        }
    }

    It "Can't find the repository" {
        InModuleScope ps-arch-wsl {
            $repository = "scottmckendry/norepositoryhere"
            $filter = "doesntmatter"
            { Get-ReleaseAsset -Repository $repository -AssetFilter $filter } | Should -Throw -ExpectedMessage "$repository doesn't exist or has no releases."
        }
    }
}
