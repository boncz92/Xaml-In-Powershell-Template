Get-ChildItem -Path $PSScriptRoot | Where-Object {$_.Name -like "*.dll"} | ForEach-Object {
    Unblock-File -Path $_.FullName
}