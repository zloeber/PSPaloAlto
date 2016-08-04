function Set-PaAddressObject {
	<#
	.SYNOPSIS
		Updates or creates a new address object on the targeted PA.
	.DESCRIPTION
		Updates or creates a new address object on the targeted PA.
	.EXAMPLE
        TBD
    .PARAMETER Name
        Name of address object
    .PARAMETER IPNetmask
        IP netmask to set on the object
    .PARAMETER Description
        Description of address object
    .PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Target
        Configuration to target, either vsys1 (default) or panorama 
	#>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [string]$Name,
        [Parameter(position=1)]
        [string]$IPNetmask,
        [Parameter(position=2)]
        [string]$Description,
        [Parameter(position=3)]
        [PSObject]$PaConnection,
        [Parameter(position=4)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand

        if ((-not $Description) -and (-not $IPNetmask) -and ($Tags.Count -eq 0)) {
            throw "$($FunctionName): Object requires a property to set!"
        }
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/address/entry[@name='" + $Name.replace(" ",'%20') + "']&element="
        if ( $IPNetmask ) {
            $Xpath += "<ip-netmask>$IPNetmask</ip-netmask>"
        }
        if ( $Description ) {
            $Xpath += "<description>" + $Description.replace(" ",'%20') + "</description>"
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
            try {
                $Addresses = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'set' -XPath $Xpath
            }
            catch {
                Write-Error "$($FunctionName): There was an issue creating this object against $($Connection.Address)..."
            }
        }
    }
}