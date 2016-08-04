function Get-PAZone {
    <#
	.SYNOPSIS
		Returns one or more zone definitions from a Palo Alto firewall.
	.DESCRIPTION
		Returns one or more zone definitions from a Palo Alto firewall.
	.EXAMPLE
        Get-PAZone -Name 'Internal'
        
        Description
        -----------
        Returns information about the zone named 'Internal' if it exists
		
    .PARAMETER Name
        Query for specific zone by name. 
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Target
        Starget the device (vsys1) or panorama pushed rules (panorama)
	#>

    Param (
        [Parameter(position=0)]
        [string]$Name,
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
        
        $xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/zone'
        
        if ( -not [string]::IsNullOrEmpty($Name) ) {
            $Xpath += '/entry[@name=%27' + $Name.replace(" ",'%20') + '%27]'
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
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $Zones = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutputZones = $Zones.response.result.zone.entry
            }
            else {
                $OutputZones = $Zones.response.result.entry
            }
            $OutputZones | ForEach {
                if ($_.network.'virtual-wire'.member) {
                    $network = $_.network.'virtual-wire'.member
                }
                elseif ($_.network.layer3.member) {
                    $network = $_.network.layer3.member
                }
                else {
                    $network = $null
                }

                 New-Object -TypeName PSObject -Property @{
                    'FirewallAddress' = $Connection.Address
                    'Name' =  $_.'Name'
                    'Network' = $network
                }
            }
        }
    }
}