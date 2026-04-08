Describe 'Assert-PathExist' {
    It 'passes for an existing path' {
        { Assert-PathExist $PSScriptRoot } | Should -Not -Throw
    }

    It 'throws for a non-existent path' {
        { Assert-PathExist '/no/such/path/xyz' } | Should -Throw
    }

    It 'passes for a file with -PathType Leaf' {
        $tempFile = New-TemporaryFile
        try {
            { Assert-PathExist $tempFile.FullName -PathType Leaf } | Should -Not -Throw
        } finally {
            Remove-Item $tempFile.FullName
        }
    }

    It 'throws for a file when expecting Container' {
        $tempFile = New-TemporaryFile
        try {
            { Assert-PathExist $tempFile.FullName -PathType Container } | Should -Throw
        } finally {
            Remove-Item $tempFile.FullName
        }
    }
}
