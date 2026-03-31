Describe 'Invoke-PySpark' {
    It 'builds correct command via -DryRun' {
        Invoke-PySpark '--version' -DryRun | Should -Be 'pyspark --version'
    }

    It 'builds correct multi-arg command via -DryRun' {
        Invoke-PySpark '--master local[4] --name test' -DryRun | Should -Be 'pyspark --master local[4] --name test'
    }
}
