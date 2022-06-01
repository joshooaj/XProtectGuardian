param(
    [Parameter(Mandatory)]
    [uri]
    $ServerAddress,

    [Parameter(Mandatory)]
    [pscredential]
    $Credential,

    [Parameter()]
    [switch]
    $BasicUser,

    [Parameter()]
    [switch]
    $IncludeChildSites,

    [Parameter(ValueFromRemainingArguments)]
    [object[]]
    $ExtraParams
)

$script:connectParams = @{
    ServerAddress     = $ServerAddress
    Credential        = $Credential
    BasicUser         = $BasicUser
    IncludeChildSites = $IncludeChildSites
    Force             = $true
    AcceptEula        = $true
    ErrorAction       = [System.Management.Automation.ActionPreference]::Stop
}

BeforeDiscovery {
    Connect-ManagementServer @connectParams
    $script:itemStates = Get-ItemState | Foreach-Object {
        $item = [VideoOS.Platform.Configuration]::Instance.GetItem($_.FQID)
        @{
            Name  = $item.Name
            Id    = $_.FQID.ObjectId
            Kind  = $_.FQID.Kind
            State = $_.State
        }
    }
    $script:registeredServices = Get-RegisteredService | ForEach-Object {
        @{
            DisplayName = if ([string]::IsNullOrWhiteSpace($_.Description)) { $_.Name } else { $_.Description }
            Name        = $_.Name
            Description = $_.Description
            Uris        = [uri[]]$_.UriArray
        }
    }
}

Describe -Name "Milestone VMS tests for $ServerAddress" {
    It 'has cameras' {
        (Get-VmsCamera).Count | Should -BeGreaterThan 0
    }

    It "Camera '<name>' is responding" -TestCases ($script:itemStates | Where-Object { $_.Kind -eq [VideoOS.Platform.Kind]::Camera }) {
        $state | Should -BeIn 'Responding', 'Communication Stopped'
    }

    It "has responsible motion detection settings" {
        foreach ($cam in Get-VmsCamera) {
            $name = '{0} ({1})' -f $cam.Name, $cam.Id
            $motion = $cam.MotionDetectionFolder.MotionDetections[0]
            $motion.KeyframesOnly | Should -BeTrue -because "$name should not be performing motion detection on all frames."
            $motion.DetectionMethod | Should -Not -Be 'Normal' -because "$name should not perform motion detection on 100% of the pixels."
        }
    }

    It "Recorder '<name>' is responding" -TestCases (Get-RecordingServer | Foreach-Object { $id = [guid]$_.Id; @{Name = $_.Name; State = ($script:itemStates | Where-Object Id -eq $id).State } }) {
        $state | Should -Be 'Server Responding'
    }

    It "<displayname> is responding" -TestCases $script:registeredServices {
        $hasOneRespondingUri = $false
        foreach ($uri in $uris) {
            $tncParams = @{
                ComputerName     = $uri.Host
                Port             = $uri.Port
                InformationLevel = 'Quiet'
            }
            if (Test-NetConnection @tncParams) {
                $hasOneRespondingUri = $true
                break
            }
        }
        $hasOneRespondingUri | Should -BeTrue -Because "$(if ($uris.Count -gt 1) {'either '})$([string]::Join(' or ', $uris)) should respond to Test-NetConnection"
    }

    AfterAll {
        if ($null -ne (Get-VmsManagementServer -ErrorAction SilentlyContinue)) {
            Disconnect-ManagementServer
        }
    }
}
