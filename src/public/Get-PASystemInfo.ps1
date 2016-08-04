function Get-PaSystemInfo {
	<#
	.SYNOPSIS
		Returns general information about the desired PA.
	.DESCRIPTION
		Returns the version number of various components of a Palo Alto firewall.
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.
    .EXAMPLE
        C:\PS> Get-PaSystemInfo
	#>

    Param (
        [Parameter(position=0)]
        [alias('pc')]
        [PSObject]$PaConnection
    )
    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
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
            (Send-PaApiQuery -PAConnection $Connection.ConnectionString  -op "<show><system><info></info></system></show>").response.result.system
        }
    }
}