function Get-WebRequestAsXML {
	<#
	.SYNOPSIS
		Queries a site and returns the result as XML.
	.DESCRIPTION
        Queries a site and returns the result as XML.
	.EXAMPLE
		<TBD>
    .PARAMETER URL
		URL to request
    .OUTPUTS
        Xml.XmlDocument
	#>
    [CmdletBinding()]
    Param (
        [Parameter(Position=0, Mandatory=$True)]
        [string]$URL,
        [Parameter(Position=1)]
        [string]$DownloadFile
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        Add-Type -AssemblyName System.Management.Automation
    }
    Process {
        try {
            if ([string]::IsNullOrEmpty($DownloadFile)) {
                return ([xml]$WebClient.DownloadString($URL))
            }
            else {
                [xml]$WebClient.DownloadString($URL, $DownloadFile)
            }
        }
        catch {
            throw "$($FunctionName): Error parsing URL!"
        }
    }
}