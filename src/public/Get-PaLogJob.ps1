function Get-PALogJob {
	<#
	.SYNOPSIS
		Formulate and send an api query to a PA firewall.
	.DESCRIPTION
		Formulate and send an api query to a PA firewall.
    .PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.
    .PARAMETER Job
        Job to retrieve
    .PARAMETER Action
        Type of job, either 'get' or 'finish'
    .EXAMPLE
        Get-PALogJob -Action 'Get' -Job 'job1'
	#>

    Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet("get","finish")]
        [String]$Action,

        [Parameter(Mandatory=$True)]
        [alias('j')]
        [String]$Job,

        [Parameter()]
        [alias('pc')]
        [String]$PaConnection
    )

    BEGIN {
        Add-Type -AssemblyName System.Web
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

        Function Process-Query ( [String]$PaConnectionString ) {
            $url = $PaConnectionString

            $url += "&type=log"
            $url += "&action=$Action"
            $Url += "&job-id=$job"

            $script:lasturl  = $url
            $script:response = [xml]$WebClient.DownloadString($url)
            if ($script:response.response.status -ne "success") {
                Throw $script:response.response.result.msg
            }

            return $script:response
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}