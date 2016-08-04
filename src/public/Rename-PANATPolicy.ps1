function Rename-PANATPolicy {
	<#
	.SYNOPSIS
		Renames existing NAT policy on the targeted PA.
	.DESCRIPTION
		Renames existing NAT policy on the targeted PA.
	.EXAMPLE
        TBD
    .PARAMETER Name
        Current object name
    .PARAMETER NewName
        New object name
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Target
        Configuration to target, either vsys1 (default) or panorama 
	#>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [string]$Name,
        [Parameter(position=1, Mandatory=$True)]
        [ValidateLength(1,32)]
        [string]$NewName,
        [Parameter(position=2)]
        [PSObject]$PaConnection,
        [Parameter(position=3)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/rulebase/nat/rules/entry[@name='" + $Name.replace(" ",'%20') + "']"
        
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
                $null = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'rename' -XPath $Xpath -NewName $NewName.replace(" ",'%20')
            }
            catch {
                Write-Warning "$($FunctionName): There was an issue renaming $($Name) to $($NewName) on $($Connection.Address)..."
            }
        }
    }
}