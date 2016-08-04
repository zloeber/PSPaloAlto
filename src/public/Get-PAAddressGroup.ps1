function Get-PAAddressGroup {
	<#
	.SYNOPSIS
		Returns information about an address group on the targeted PA.
	.DESCRIPTION
		Returns information about an address group on the targeted PA.
	.EXAMPLE
        Get-PAAddressGroup
        
        Description
        -------------
        Returns a list of all address groups on all connected PAs
    .PARAMETER Name
        Specify a name to query 
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
        
        $Xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/address-group'
        
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
            $Groups = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutObjects = $Groups.response.result.'address-group'.entry
            }
            else {
                $OutObjects = $Groups.response.result.entry
            }
            if ($OutObjects -ne $null) {
                $OutObjects | ForEach-Object {
                    $OutProp = @{
                        'FirewallAddress' = $Connection.Address
                        'Name' = Text-Query $_ 'Name'
                    }
                    if ($_.static) {
                        $OutProp.MemberType = 'Static'
                        $OutProp.Members = Text-Query $_.static 'member'
                    }
                    else {
                        $OutProp.MemberType = 'Dynamic'
                        $OutProp.Members = Text-Query $_.dynamic 'filter'
                    }
                    
                    New-Object -TypeName PSObject -Property $OutProp
                }
            }
        }
    }
}