function New-PaLogJob {
	<#
	.SYNOPSIS
        Create a new log request job.
	.DESCRIPTION
		Create a new log request job.
    .PARAMETER Type
        Type of log to request.
    .PARAMETER Query
        Log filter or query to use.
    .PARAMETER NumberLogs
        Number of logs to retrieve
    .PARAMETER Skip
        Skip logs with this string.
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .EXAMPLE
        TBD
	#>

    Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet("traffic","threat","config","system","hip-match")]
        [String]$Type,

        [Parameter(Mandatory=$True)]
        [String]$Query,

        [Parameter()]
        [ValidateRange(1,5000)]
        [Decimal]$NumberLogs,

        [Parameter()]
        [String]$Skip,

        [Parameter()]
        [String]$PaConnection
    )

    BEGIN {
        Add-Type -AssemblyName System.Web
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

        Function Process-Query ( [String]$PaConnectionString ) {
            $url = $PaConnectionString

            $url += "&type=log"
            $url += "&log-type=$Type"

            if ($Query)      { $Query  = [System.Web.HttpUtility]::UrlEncode($Query)
                               $url   += "&query=$Query" }
            if ($NumberLogs) { $url += "&nlogs=$NumberLogs" }
            if ($Skip)       { $url += "&skip=$SkipLogs" }

            $global:lasturl  = $url
            $global:response = [xml]$WebClient.DownloadString($url)
            if ($global:response.response.status -ne "success") {
                Throw $global:response.response.result.msg
            }

            return $global:response
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