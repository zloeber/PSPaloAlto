function Watch-PaJob {
    <#
	.SYNOPSIS
		Watch a given Jobs progress.
	.DESCRIPTION
		Watch a given Jobs progress.
    .PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, the current connections will be used
	.PARAMETER Job
        Job to watch
    .PARAMETER Size
    Size
    .PARAMETER Id
    Id
    .PARAMETER Parentid
    Parentid
    .PARAMETER Caption
    Caption
	.EXAMPLE
        TBD
	#>

    Param (
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter(Mandatory=$True)]
        [Decimal]$Job,
        [Parameter()]
        [Decimal]$Size,
        [Parameter()]
        [Decimal]$Id,
        [Parameter()]
        [Decimal]$Parentid,
        [Parameter(Mandatory=$True)]
        [String]$Caption
    )

    BEGIN {
        Function Process-Query ( [String]$PaConnectionString ) {
            $cmd = "<show><jobs><id>$Job</id></jobs></show>"
            $JobStatus = Send-PaApiQuery -op "$cmd"
            $TimerStart = Get-Date
            
            $ProgressParams = @{}
            $ProgressParams.add("Activity",$Caption)
            if ($Id)       { $ProgressParams.add("Id",$Id) }
            if ($ParentId) { $ProgressParams.add("ParentId",$ParentId) }
            $ProgressParams.add("Status",$null)
            $ProgressParams.add("PercentComplete",$null)

            while ($JobStatus.response.result.job.status -ne "FIN") {
                $JobProgress = $JobStatus.response.result.job.progress
                $SizeComplete = ([decimal]$JobProgress * $Size)/100
                $Elapsed = ((Get-Date) - $TimerStart).TotalSeconds
                if ($Elapsed -gt 0) { $Speed = [math]::Truncate($SizeComplete/$Elapsed*1024) }
                $Status = $null
                if ($size)          { $Status = "$Speed`KB/s " } 
                $Status += "$($JobProgress)% complete"
                $ProgressParams.Set_Item("Status",$Status)
                $ProgressParams.Set_Item("PercentComplete",$JobProgress)
                Write-Progress @ProgressParams
                $JobStatus = Send-PaApiQuery -op "$cmd"
            }
            $ProgressParams.Set_Item("PercentComplete",100)
            Write-Progress @ProgressParams
            return $JobStatus
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $Global:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}