param(
    [Parameter(Mandatory)]
    [pscustomobject[]]
    $Urls
)

$testUris = @()
foreach ($url in $Urls) {
    $testUris += @{ Uri = [uri]$url.Url; Comment = $url.Comment }
}

Describe -Name "<uri> - <comment>" -ForEach $testUris {
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

    It 'is up' {
        $shouldNotBeDown = $ExpectDown -ne 'True'
        $certInfo | Should -Not:$shouldNotBeDown -BeNullOrEmpty
    }

    It 'is not expired' {
        $shouldNotBeExpired = $ExpectExpired -ne 'True'
        $certInfo.NotAfter | Should -Not:$shouldNotBeExpired -BeGreaterThan (Get-Date)
    }

    It 'is valid for at least 29 days' {
        $certInfo.NotAfter | Should -BeGreaterThan (Get-Date).AddDays(29)
    }

    It 'is trusted certificate' {
        $certInfo.Verify() | Should -BeTrue
    }

    AfterAll {
        if ($script:sslStream) {
            $script:sslStream.Dispose()
        }
    }
}
