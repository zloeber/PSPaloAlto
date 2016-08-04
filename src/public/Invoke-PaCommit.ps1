function Invoke-PACommit {
	<#
	.SYNOPSIS
		Invokes a configuratino commit to the PA.
	.DESCRIPTION
		Invokes a configuratino commit to the PA
	.EXAMPLE
        TBD
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Force
        Force the commit if possible.
	#>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [PSObject]$PaConnection,

        [Parameter()]
        [switch]$Force
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
        
            if ($Force) {
                $CustomData = Send-PaApiQuery -PAConnection $Connection.ConnectionString -commit -force
            }
            else {
                $CustomData = Send-PaApiQuery -PAConnection $Connection.ConnectionString -commit
            }
            if ($CustomData.response.status -eq "success") {
                if ($CustomData.response.msg -match "no changes") {
                    Write-Warning "$($FunctionName): There are no changes to commit."
                }
                $job = $CustomData.response.result.job
                $cmd = "<show><jobs><id>$job</id></jobs></show>"
                $JobStatus = Send-PaApiQuery -PAConnection $Connection.ConnectionString -op "$cmd"
                while ($JobStatus.response.result.job.status -ne "FIN") {
                    Write-Progress -Activity "Commiting to PA" -Status "$($JobStatus.response.result.job.progress)% complete"-PercentComplete ($JobStatus.response.result.job.progress)
                    $JobStatus = Send-PaApiQuery -op "$cmd"
                    sleep -Seconds 1
                }
                Write-Output $JobStatus.response.result.job
                return
            }
            throw "$($CustomData.response.result.msg)"
        }
    }
}