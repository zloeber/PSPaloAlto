function Get-PaSecurityPolicy {
    <#
	.SYNOPSIS
		Returns Security policies from Palo Alto firewall.
	.DESCRIPTION
		Returns NAT Ruleset from Palo Alto firewall.
        
	.EXAMPLE
        Get-PaSecurityPolicy
        
        Description
        -----------
        Return all information about all security rules found, including the order they are found in.
		
    .PARAMETER Rule
        Query for specific rule by name. Order will not be returned if this parameter is specified.
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Target
        Starget the device (vsys1) or panorama pushed rules (panorama)
    .PARAMETER Candidate
        Query the candidate configuration.
	#>

    Param (
        [Parameter(position=0)]
        [string]$Rule,
        [Parameter(position=1)]
        [alias('pc')]
        [String]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1',
        [Parameter(position=3)]
        [switch]$Candidate
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        if ($Candidate) {
            $type = "get"
        }
        else {
            $type = "show"
        }

        $xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/rulebase/security/rules'
        
        if ( -not [string]::IsNullOrEmpty($Rule) ) {
            $Xpath += '/entry[@name=%27' + $Rule.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
        
        $ReturnObjectOrder = @(
            'Order',
            'FirewallAddress',
            'Name',
            'Disabled',
            'Description',
            'Tags',
            'SourceZone',
            'SourceAddress',
            'SourceNegate',
            'SourceUser',
            'HipProfile',
            'DestinationZone',
            'DestinationAddress',
            'DestinationNegate',
            'Application',
            'Service',
            'UrlCategory',
            'Action',
            'ProfileType',
            'ProfileGroup',
            'ProfileVirus',
            'ProfileVuln',
            'ProfileSpy',
            'ProfileUrl',
            'ProfileFile',
            'ProfileData',
            'LogStart',
            'LogEnd',
            'LogForward',
            'DisableSRI',
            'Schedule',
            'QosType',
            'QosMarking'
        )
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $RuleCount = 0
            $SecurityRules = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config $type -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Rule) ) {
                $OutputRules = $SecurityRules.response.result.rules.entry
            }
            else {
                $OutputRules = $SecurityRules.response.result.entry
            }
            $OutputRules | ForEach {
                $ReturnObject = New-Object -TypeName PSObject -Property @{
                    'Order' = if ( -not [string]::IsNullOrEmpty($Rule) ) { $null } else { $RuleCount }
                    'FirewallAddress' = $Connection.Address
                    'Name' = $_.Name
                    'Disabled' = if ((Text-Query $_ 'disabled') -eq 'yes') {$true} else {$false}
                    'Description' = $_.Description
                    'Tags' = Member-Query $_ 'tag'
                    'SourceZone' = Member-Query $_ 'from'
                    'SourceAddress' = Member-Query $_ 'source'
                    'SourceNegate' = Text-Query $_ 'negate-source'
                    'SourceUser' = Member-Query $_ 'source-user'
                    'HipProfile' = Member-Query $_ 'hip-profiles'
                    'DestinationZone' = Member-Query $_ 'to'
                    'DestinationAddress' =  Member-Query $_ 'destination'
                    'DestinationNegate' = Text-Query $_ 'negate-destination'
                    'Application' = Member-Query $_ 'application'
                    'Service' = Member-Query $_ 'service'
                    'UrlCategory' = Member-Query $_ 'category'
                    'Action' = Text-Query $_ 'action'
                    'ProfileType' = $null
                    'ProfileGroup' = $null
                    'ProfileVirus' = $null
                    'ProfileVuln' = $null
                    'ProfileSpy' = $null
                    'ProfileUrl' = $null
                    'ProfileFile' = $null
                    'ProfileData' = $null
                    'LogStart' = Text-Query $_ 'log-start'
                    'LogEnd' = Text-Query $_ 'log-end'
                    'LogForward' = Text-Query $_ 'log-setting'
                    'DisableSRI' = Text-Query $_.option 'disable-server-response-inspection'
                    'Schedule' = Text-Query $_ 'schedule'
                    'QosType' = $null
                    'QosMarking' = $null
                }

                if ($_.'profile-setting'.group) {
                    $ReturnObject.ProfileGroup   = Member-Query $_.'profile-setting' 'group'
                    $ReturnObject.ProfileType    = 'group'
                }
                elseif ($_.'profile-setting'.profiles) {
                    $ReturnObject.ProfileType    = 'profiles'
                    $ReturnObject.ProfileVirus   = Member-Query $_.'profile-setting'.profiles 'virus'
                    $ReturnObject.ProfileVuln    = Member-Query $_.'profile-setting'.profiles 'vulnerability'
                    $ReturnObject.ProfileSpy     = Member-Query $_.'profile-setting'.profiles 'spyware'
                    $ReturnObject.ProfileUrl     = Member-Query $_.'profile-setting'.profiles 'url-filtering'
                    $ReturnObject.ProfileFile    = Member-Query $_.'profile-setting'.profiles 'file-blocking'
                    $ReturnObject.ProfileData    = Member-Query $_.'profile-setting'.profiles 'data-filtering'
                }

                if ($_.qos.marking.'ip-dscp') {
                    $ReturnObject.QosType        = 'ip-dscp'
                    $ReturnObject.QosMarking     = Text-Query $_.qos.marking 'ip-dscp'
                }
                elseif ($_.qos.marking.'ip-precedence') {
                    $ReturnObject.QosType        = 'ip-precedence'
                    $ReturnObject.QosMarking     = Text-Query $_.qos.marking 'ip-precedence'
                }

                $RuleCount++
                $ReturnObject | Select $ReturnObjectOrder
            }
        }
    }
}