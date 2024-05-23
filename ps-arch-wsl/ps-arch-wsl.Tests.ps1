BeforeAll {
    Import-Module $PSScriptRoot/ps-arch-wsl.psm1 -Force
}

Describe "Get-ReleaseAsset" {
    It "Finds the release asset" {
        InModuleScope ps-arch-wsl {
            $foundAsset = Get-ReleaseAsset -Repository "yuk7/ArchWSL" -AssetFilter "cer"
            $latestCertificateInTemp = Get-ChildItem $env:Temp | Where-Object { $_.FullName -like "*.cer" } | Sort-Object -Property CreationTime -Descending
            $foundAsset.Split("\")[-1] | Should -Be $latestCertificateInTemp[0].FullName.Split("\")[-1]
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

Describe "Convert-LineEndings" {
    It "Converts line endings for a file with CRLF" {
        InModuleScope ps-arch-wsl {
            $testFile = "$env:TEMP\testfile.txt"
            $content = "This is a test file with CRLF`r`nit should be converted to LF"
            Set-Content -Path $testFile -Value $content -NoNewline
            Convert-LineEndings -Path $testFile
            $convertedContent = Get-Content -Path $testFile -Raw
            $convertedContent | Should -Be "This is a test file with CRLF`nit should be converted to LF"
        }
    }

    It "Can't find the file" {
        InModuleScope ps-arch-wsl {
            $nonExistentFile = "$env:TEMP\nofilehere.txt"
            { Convert-LineEndings -Path $nonExistentFile } | Should -Throw -ExpectedMessage "Failed to convert line endings: File not found at $nonExistentFile."
        }
    }
}
