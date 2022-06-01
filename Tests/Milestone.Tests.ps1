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
    
}

Describe -Name "Milestone VMS tests for $ServerAddress" {
    It 'has cameras' {
        (Get-VmsCamera).Count | Should -BeGreaterThan 0
    }

    It "Camera '<name>' is responding" -TestCases ($script:itemStates | Where-Object {$_.Kind -eq [VideoOS.Platform.Kind]::Camera}) {
        $state | Should -BeIn 'Responding', 'Communication Stopped'
    }

    It "Recorder '<name>' is responding" -TestCases (Get-RecordingServer | Foreach-Object { $id = [guid]$_.Id; @{Name = $_.Name; State = ($script:itemStates | Where-Object Id -eq $id).State } }) {
        $state | Should -Be 'Server Responding'
    }

    AfterAll {
        if ($null -ne (Get-VmsManagementServer -ErrorAction SilentlyContinue)) {
            Disconnect-ManagementServer
        }
    }
}