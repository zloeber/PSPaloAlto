function Get-PaAddressObject {
	<#
	.SYNOPSIS
		Returns information abbout address objects on the targeted PA.
	.DESCRIPTION
		Returns information abbout address objects on the targeted PA.
	.EXAMPLE
        Get-PaAddressObject
        
        Description
        -----------
        Returns information about all defined address objects.
    .PARAMETER Name
        Name of an address object to retrieve. If not specified all address objects will be listed.
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.
    .PARAMETER Target
        Specify either vsys1 (the local device configuration) or panorama configurations
	#>
    [CmdletBinding()]
    Param (
        [Parameter(position=0)]
        [string]$Name,
        [Parameter(position=1)]
        [alias('pc')]
        [PSObject]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/address'
        
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
            $Addresses = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutObjects = $Addresses.response.result.address.entry
            }
            else {
                $OutObjects = $Addresses.response.result.entry
            }
            if ($OutObjects -ne $null) {
                $OutObjects | ForEach-Object {
                    New-Object -TypeName PSObject -Property @{
                        'FirewallAddress' = $Connection.Address
                        'Name' = Text-Query $_ 'Name'
                        'IP-Netmask' = Text-Query $_ 'ip-netmask'
                        'Description' = Text-Query $_ 'Description'
                        'tags' = Member-Query $_ 'tag'
                    }
                }
            }
        }
    }
}