function Get-PaConnectionString {
	<#
    .SYNOPSIS
    Connects to a Palo Alto firewall and generates a connection object for use with this module.
    .DESCRIPTION
    Connects to a Palo Alto firewall and returns an connection object that includes the API key, connection string, and address.
    .EXAMPLE
    PS> Connect-Pa -Address 192.168.1.1 -Cred $PSCredential

    .PARAMETER Address
    Specifies the IP or FQDN of the system to connect to.
    .PARAMETER Cred
    Specifiy a PSCredential object, If no credential object is specified, the user will be prompted.
    .PARAMETER IgnoreSSL
    Ignores SSL issues
    .OUTPUTS
    PSObject
	#>
    [CmdletBinding()]
    Param (
        [Parameter( Mandatory=$True )]
        [string]$Address,
        [Parameter( Mandatory=$True )]
        [alias('Credential')]
        [System.Management.Automation.PSCredential]$Cred,
        [Parameter()]
        [string]$IgnoreSSL
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
    }

    Process {
        $user = $cred.UserName.Replace("\","")
        $password = ($cred.getnetworkcredential()).password
        $headers = @{'X-Requested-With'='powershell'}
        $URL = 'https://{0}/api/?type=keygen&user={1}&password={2}' -f $Address,$user,$password
        Write-Verbose "$($FunctionName): URL = $URL"
        if ($Script:_IgnoreSSL -or $IgnoreSSL) { Ignore-SSL }
        try {
            $response = Invoke-RestMethod -Headers $headers -Uri $url -Method Post -Credential $cred
            if ($response.response.status -eq 'success') {
                $CurrentConnection = New-Object -TypeName PsObject -Property @{
                    'Address' = $Address
                    'APIKey' = $response.response.result.key
                    'ConnectionString' = "https://$Address/api/?key=$($response.response.result.key)"
                }

                return $CurrentConnection
            }
            else {
                throw "$($FunctionName): HTTPS connection error $($response.response.status)"
            }
        }
        catch {
            throw "$($FunctionName): HTTPS connection error $($response.response.status)"
        }
    }
}