if ([string]::IsNullOrWhiteSpace($env:GHURL)) {
    throw "The GHURL environment variable must be set."
}
if ([string]::IsNullOrWhiteSpace($env:GHTOKEN)) {
    throw "The GHTOKEN environment variable must be set."
}

& .\config.cmd --url $env:GHURL --token $env:GHTOKEN --unattended --ephemeral
$env:GHURL = ''
$env:GHTOKEN = ''
Clear-History
& .\run.cmd