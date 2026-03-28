 $cmd = Get-Command python -ErrorAction Ignore
$file = Get-Item $cmd.Source -Force -ErrorAction Ignore
[PSCustomObject]@{
    Source     = $cmd.Source
    Length     = $file.Length
    Reparse   = $file.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)
    Attributes = $file.Attributes
}
