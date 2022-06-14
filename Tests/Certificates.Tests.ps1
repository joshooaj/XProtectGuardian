param(
    [Parameter(Mandatory)]
    [pscustomobject[]]
    $Urls,

    [Parameter(ValueFromRemainingArguments)]
    [object[]]
    $ExtraParams
)

$testCases = [system.collections.generic.list[hashtable]]::new()
[bool]$boolValue
foreach ($url in $Urls) {
    $testCase = @{ Uri = [uri]$url.Url }
    foreach ($key in $url | Get-Member -MemberType NoteProperty | Select-Object -Expand Name) {
        if (!$testCase.ContainsKey($key)) {
            if ($key.StartsWith('Expect')) {
                $testCase.$key = [bool]::Parse($url.$key)
            } else {
                $testCase.$key = $url.$key
            }
        }
    }
    $testCases.Add($testCase)
}

Describe -Name "<uri> - <comment>" -ForEach $testCases {
    BeforeAll {
        if ($null -eq $Uri) {
            throw "Data driven test received no data. The value of `$Uri is `$null"
        }
        try {
            $script:certInfo = $null
            $tcpClient        = [net.sockets.tcpclient]::new($Uri.Host, $Uri.Port)
            $stream           = $tcpClient.GetStream()
            $sslStream = [net.security.sslstream]::new($stream, $false, { $true })
            $sslStream.AuthenticateAsClient($Uri.Host)
            $script:certInfo  = [security.cryptography.x509certificates.x509certificate2]::new($sslStream.RemoteCertificate)
        } catch {
            Write-Host "Could not connect to $Uri" -ForegroundColor Red
        }
    }

    It 'is up' -Skip:$ExpectDown {
        $certInfo | Should -Not -BeNullOrEmpty
    }
    It 'is down' -Skip:(!$ExpectDown) {
        $certInfo | Should -BeNullOrEmpty
    }

    It 'is not expired' -Skip:($ExpectDown -or $ExpectExpired) {
        $certInfo.NotAfter | Should -BeGreaterThan (Get-Date)
    }
    It 'is expired' -Skip:($ExpectDown -or !$ExpectExpired) {
        $certInfo.NotAfter | Should -Not -BeGreaterThan (Get-Date)
    }

    It 'is valid for at least 29 days' -Skip:($ExpectDown -or $ExpectExpiring) {
        $certInfo.NotAfter | Should -BeGreaterThan (Get-Date).AddDays(29)
    }
    It 'is not valid for at least 29 days' -Skip:($ExpectDown -or !$ExpectExpiring) {
        $certInfo.NotAfter | Should -Not -BeGreaterThan (Get-Date).AddDays(29)
    }

    It 'is trusted certificate' -Skip:($ExpectDown -or $ExpectUntrusted) {
        $certInfo.Verify() | Should -BeTrue
    }
    It 'is not trusted certificate' -Skip:($ExpectDown -or !$ExpectUntrusted) {
        $certInfo.Verify() | Should -BeFalse
    }

    AfterAll {
        if ($script:sslStream) {
            $script:sslStream.Dispose()
        }
    }
}
