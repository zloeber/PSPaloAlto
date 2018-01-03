function Set-PaAddressObjectTag {
    <#
    .SYNOPSIS
    Updates an address object's assigned tags.
    .DESCRIPTION
    Updates an address object's assigned tags.
    .EXAMPLE
    TBD
    .PARAMETER Name
    Name of object to update
    .PARAMETER Tags
    Tags to assign
    .PARAMETER PaConnection
    Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Target
    Configuration to target, either vsys1 (default) or panorama
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True,ValueFromPipeline=$True)]
        [string]$Name,
        [Parameter(position=1, Mandatory=$True)]
        [string]$Tags,
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter()]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand

        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/address/entry[@name='" + $Name.replace(" ",'%20') + "']/tag"

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
                $Addresses = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'set' -XPath $Xpath -Member $Tags
            }
            catch {
                Write-Error "$($FunctionName): There was an issue creating this object against $($Connection.Address)..."
            }
        }
    }
}