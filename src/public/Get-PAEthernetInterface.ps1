function Get-PAEthernetInterface {
    <#
	.SYNOPSIS
		Returns one or more Interface definitions from a Palo Alto firewall.
	.DESCRIPTION
		Returns one or more Interface definitions from a Palo Alto firewall.
	.EXAMPLE
        Get-PAEthernetInterface -Name 'ethernet1/1'
        
        Description
        -----------
        Returns information about the Interface named 'ethernet1/1' if it exists
        
	.EXAMPLE
        Get-PAEthernetInterface
        
        Description
        -----------
        Returns information about all defined Interfaces.
		
    .PARAMETER Name
        Query for specific interface by name. 
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.
    .PARAMETER Aggregate
        Target aggregate interfaces.
	#>

    Param (
        [Parameter(position=0)]
        [string]$Name,
        [Parameter(position=1)]
        [PSObject]$PaConnection,
        [Parameter(position=2)]
        [switch]$Aggregate
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
       
        #$xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/network/interface/ethernet'
        if (-not $Aggregate) {
            $xpath = '/config/devices/entry/network/interface/ethernet'
            $inttype = 'ethernet'
        }
        else {
            $xpath = '/config/devices/entry/network/interface/aggregate-ethernet'
             $inttype = 'aggregate-ethernet'
        }
        
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
            $Interfaces = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutputInterfaces = $Interfaces.response.result.$inttype.entry
            }
            else {
                $OutputInterfaces = $Interfaces.response.result.entry
            }
            $OutputInterfaces | ForEach {
                $objprops = @{
                    'FirewallAddress' = $Connection.Address
                    'Name' =  $_.'Name'
                    'aggregate-group' = Text-Query $_ 'aggregate-group'
                    'link-duplex' = Text-Query $_ 'link-duplex'
                    'link-speed' = Text-Query $_ 'link-speed'
                    'link-state' = Text-Query $_ 'link-state'
                    'lacp-port-priority' = Text-Query $_.lacp 'port-priority'
                    'ip' = $null
                    'interface-management-profile' = Text-Query $_ 'interface-management-profile'
                    'ipv6' = $null
                    'tag' = Text-Query $_ 'tag'
                    'comment' =  Text-Query $_ 'comment'
                }
                $subinterfaces = $_.layer3.units.entry
                
                # First output the initial interface
                New-Object -TypeName PSObject -Property $objprops
                
                # If we have any subinterfaces output these as well
                # As usual I'm only grabbing a small subset of the common properties.
                if ($subinterfaces.Count -gt 0) {
                    ForEach ($int in $subinterfaces) {
                        $objprops.Name = Text-Query $int 'Name'
                        $objprops.'interface-management-profile' = Text-Query $int 'interface-management-profile'
                        $objprops.tag = Text-Query $int 'tag'
                        $objprops.comment =  Text-Query $int 'comment'
                        $objprops.ip = Text-Query $int.ip.entry name
                        
                        New-Object -TypeName PSObject -Property $objprops
                    }
                }
            }
        }
    }
}