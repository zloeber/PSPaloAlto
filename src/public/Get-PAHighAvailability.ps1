function Get-PAHighAvailability {
	<#
	.SYNOPSIS
		Returns HA information about the desired PA.
	.DESCRIPTION
		Returns HA information about the desired PA.
	.PARAMETER PaConnection
		Connection object for a PA (otherwise an internal array of previously connected PA strings will be used)
	.EXAMPLE
        C:\PS> PAHighAvailability       
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
            $result = (Send-PaApiQuery -PAConnection $Connection.ConnectionString  -op "<show><high-availability><all></all></high-availability></show>").response.result
            if  ($result.enabled -eq 'yes') {
                $ResultOutput = @{
                     'FirewallAddress' = $Connection.Address
                     'Enabled' = $true
                     'Mode' = Text-Query $result.group.mode
                 }
                $result.group."local-info" | get-member | Where {$_.MemberType -eq 'Property'} | foreach {
                    $ResultOutput.$($_.Name) = $result.group.'local-info'.$($_.Name)
                 }
                 $ResultOutput.'running-sync' = $result.group.'running-sync'
                 $ResultOutput.'running-sync-enabled' = $result.group.'running-sync-enabled'
                 $result.group."peer-info" | get-member | Where {$_.MemberType -eq 'Property'} | foreach {
                    $ResultOutput.$('peer-' + $_.Name) = $result.group.'peer-info'.$($_.Name)
                 }
                 
                 New-Object -TypeName PSObject -Property $ResultOutput
            }
            else {
                $ResultOutput = @{
                     'FirewallAddress' = $Connection.Address
                     'Enabled' = $false
                 }
                 New-Object -TypeName PSObject -Property $ResultOutput
            }
        }
    }
}