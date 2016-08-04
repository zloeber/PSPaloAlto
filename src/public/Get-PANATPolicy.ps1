function Get-PaNatPolicy {
    <#
	.SYNOPSIS
		Returns NAT Ruleset from Palo Alto firewall.
	.DESCRIPTION
		Returns NAT Ruleset from Palo Alto firewall.
        
	.EXAMPLE
        Get-PaNatPolicy
        
        Description
        -----------
        Return all information about all nat rules found, including the order they are found in.
		
    .PARAMETER Rule
        Query for specific rule by name. Order will not be returned if this parameter is specified.
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.
    .PARAMETER Target
        Specify either vsys1 (the local device configuration) or panorama configurations
	#>

    Param (
        [Parameter(position=0)]
        [string]$Rule,
        [Parameter(position=1)]
        [alias('pc')]
        [String]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/rulebase/nat/rules'
        
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
            'DestinationZone',
            'DestinationInterface',
            'Service',
            'SourceAddress',
            'DestinationAddress',
            'SourceTransType',
            'SourceTransAddressType',
            'SourceTransInterface',
            'SourceTransAddress',
            'BiDirectional',
            'DestTransEnabled',
            'DestTransAddress',
            'DestTransPort'
        )
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $RuleCount = 0
            $NATRules = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Rule) ) {
                $OutputRules = $NATRules.response.result.rules.entry
            }
            else {
                $OutputRules = $NATRules.response.result.entry
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
                    'DestinationZone' = Member-Query $_ 'to'
                    'DestinationInterface' = Text-Query $_ 'to-interface'
                    'Service' = Text-Query $_ 'service'
                    'SourceAddress' = Member-Query $_ 'source'
                    'DestinationAddress' = Member-Query $_ 'destination'
                    'SourceTransType' = $null
                    'SourceTransAddressType' = $null
                    'SourceTransInterface' = $null
                    'SourceTransAddress' = $null
                    'BiDirectional' = $null
                    'DestTransEnabled' = $null
                    'DestTransAddress' = $null
                    'DestTransPort' = $null
                }
                    
                if ($_."source-translation"."dynamic-ip-and-port") {
                    $ReturnObject.SourceTransType = "DynamicIpAndPort"
                    if ($_."source-translation"."dynamic-ip-and-port"."interface-address".interface."#text") {
                        $ReturnObject.SourceTransAddressType = "InterfaceAddress"
                        $ReturnObject.SourceTransInterface = Text-Query $_."source-translation"."dynamic-ip-and-port"."interface-address" 'interface'
                        $ReturnObject.SourceTransAddress = Text-Query "source-translation"."dynamic-ip-and-port"."interface-address" 'ip'
                    }
                    elseif ($_."source-translation"."dynamic-ip-and-port"."interface-address".interface) {
                        $ReturnObject.SourceTransAddressType = "InterfaceAddress"
                        $ReturnObject.SourceTransInterface = Text-Query $_."source-translation"."dynamic-ip-and-port"."interface-address" 'interface'
                    }
                    elseif ($_."source-translation"."dynamic-ip-and-port"."translated-address") {
                        $ReturnObject.SourceTransAddressType = "TranslatedAddress"
                        $ReturnObject.SourceTransInterface = Text-Query $_."source-translation"."dynamic-ip-and-port" 'translated-address'
                    }
                }
                elseif ($_."source-translation"."static-ip") {
                    $ReturnObject.SourceTransType = "StaticIp"
                    $ReturnObject.SourceTransAddress = Text-Query $_."source-translation"."static-ip" 'translated-address'
                    $ReturnObject.BiDirectional = Text-Query $_."source-translation"."static-ip" 'bi-directional'
                }
                elseif ($_."source-translation"."dynamic-ip") {
                    $ReturnObject.SourceTransType = "DynamicIp"
                    $ReturnObject.SourceTransAddress = Text-Query $_."source-translation"."dynamic-ip"."translated-address" 'member'
                }
                if ($_."destination-translation") {
                    $ReturnObject.DestTransEnabled = "yes"
                    $ReturnObject.DestTransAddress = Text-Query $_."destination-translation" 'translated-address'
                    $ReturnObject.DestTransPort = Text-Query $_."destination-translation" 'translated-port'
                }

                $RuleCount++
                $ReturnObject | Select $ReturnObjectOrder
            }
        }
    }
}