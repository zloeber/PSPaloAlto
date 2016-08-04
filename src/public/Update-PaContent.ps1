function Update-PaContent {
    <#
	.SYNOPSIS
		Updates Pa Content files.
	.DESCRIPTION
		Updates Pa Content files.
	.PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.
	.EXAMPLE
        Update-PaContent
        
        Description
        -------------
        Updates the content files of the currently connected Palo Alto firewalls.
	#>

    Param (
        [Parameter(Mandatory=$False)]
        [alias('pc')]
        [String]$PaConnection
    )

    BEGIN {
        Function Process-Query ( [String]$PaConnectionString ) {
            $UpToDate = $false

            $xpath = "<request><content><upgrade><check></check></upgrade></content></request>"
            Write-Verbose "checking for new content"
            $ContentUpdate = Send-PaApiQuery -Op $xpath
            if ($ContentUpdate.response.status -ne "success") { throw $ContentUpdate.response.msg }
            if ($ContentUpdate.response.result."content-updates".entry.current -eq "no") {            
                if ($ContentUpdate.response.result."content-updates".entry.downloaded -eq "no") {
                    $xpath = "<request><content><upgrade><download><latest></latest></download></upgrade></content></request>"
                    $ContentDownload = Send-PaApiQuery -Op $xpath
                    if ($ContentDownload.response.status -ne "success") { throw $ContentDownload.response.msg }
                    
                    $job = $ContentDownload.response.result.job
                    $size = [Decimal]($ContentUpdate.response.result."content-updates".entry.size)
                    $Version = $ContentUpdate.response.result."content-updates".entry.version
                    $Status = Watch-PaJob -Job $job -c "Downloading $Version" -s $Size
                    if ($Status.response.status -ne "success") { throw $Status.response.msg }
                }
                else {
                    Write-Verbose "content already downloaded"
                }
                $xpath = "<request><content><upgrade><install><version>latest</version></install></upgrade></content></request>"
                $ContentInstall = Send-PaApiQuery -Op $xpath
                $Job = $ContentInstall.response.result.job
                $Status = Watch-PaJob -Job $job -c "Installing content $Version"
                
                if ($Status.response.result.job.details.Line.newjob.nextjob) {
                    $Job = $Status.response.result.job.details.Line.newjob.nextjob
                    $Status = Watch-PaJob -Job $job -c "New content push"
                }
            } 
            else {
                $UpToDate = $true
                Write-Verbose "content already installed"
            }

            $xpath = "<request><anti-virus><upgrade><check></check></upgrade></anti-virus></request>"
            "checking for new antivirus"
            $AvUpdate = Send-PaApiQuery -Op $xpath
            if ($AvUpdate.response.status -ne "success") { throw $AvUpdate.response.msg }

            if ($AvUpdate.response.result."content-updates".entry.current -eq "no") {
                if ($AvUpdate.response.result."content-updates".entry.downloaded -eq "no") {
                    $xpath = "<request><anti-virus><upgrade><download><latest></latest></download></upgrade></anti-virus></request>"
                    $AvDownload = Send-PaApiQuery -Op $xpath
                    if ($AvDownload.response.status -ne "success") { throw $AvDownload.response.msg }
                    
                    $job = $AvDownload.response.result.job
                    $size = [Decimal]($AvUpdate.response.result."content-updates".entry.size)
                    $Version = $AvUpdate.response.result."content-updates".entry.version
                    $Status = Watch-PaJob -Job $job -c "Downloading antivirus $Version" -s $Size
                    if ($Status.response.status -ne "success") { throw $Status.response.msg }
                }
                else {
                    Write-Verbose "antivirus already downloaded"
                }
                $xpath = "<request><anti-virus><upgrade><install><version>latest</version></install></upgrade></anti-virus></request>"
                $AvInstall = Send-PaApiQuery -Op $xpath
                if ($AvInstall.response.status -ne "success") { throw $AvInstall.response.msg }
                
                $job = $AvInstall.response.result.job
                $Status = Watch-PaJob -Job $Job -c "Installing antivirus $Version"
                if ($Status.response.status -ne "success") { throw $Status.response.msg }
                
                if ($status.response.result.job.details.line.newjob.nextjob) {
                    $Job = $status.response.result.job.details.line.newjob.nextjob
                    $Status = Watch-PaJob -Job $job -c "pushing antivirus"
                }
            } else {
                $UpToDate = $true
                "antivirus already install"
            }

            return $UpToDate
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