if ([string]::IsNullOrWhiteSpace($env:GHURL)) {
    throw "The GHURL environment variable must be set."
}
if ([string]::IsNullOrWhiteSpace($env:GHTOKEN)) {
    throw "The GHTOKEN environment variable must be set."
}

if ($env:GHEPHEMERAL -eq 'True') {
    & .\config.cmd --url $env:GHURL --token $env:GHTOKEN --unattended --ephemeral
} else {
    & .\config.cmd --url $env:GHURL --token $env:GHTOKEN --unattended
}
$env:GHTOKEN = ''
Clear-History
& .\run.cmd