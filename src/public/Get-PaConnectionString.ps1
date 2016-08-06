function Get-PaConnectionString {
	<#
	.SYNOPSIS
		Creates a pa connection string for the specified credentials.
	.DESCRIPTION
		Creates a pa connection string for the specified credentials.

    .PARAMETER Address
		Specifies the IP or FQDN of the system to connect to.
    .PARAMETER Cred
        Specifiy a PSCredential object, If no credential object is specified, the user will be prompted.
	.EXAMPLE
		C:\PS> Connect-Pa 192.168.1.1
        https://192.168.1.1/api/?key=LUFRPT1SanJaQVpiNEg4TnBkNGVpTmRpZTRIamR4OUE9Q2lMTUJGREJXOCs3SjBTbzEyVSt6UT01

        c:\PS> Get-PaConnectionString -Address 192.168.1.1 -Cred (Get-Credential)

        ConnectionString                 ApiKey                           Address
        ----------------                 ------                           -------
        https://192.168.1.1/api/?key=... LUFRPT1SanJaQVpiNEg4TnBkNGVpT... 192.168.1.1

    .OUTPUTS
        PSObject
	#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [ValidatePattern("\d+\.\d+\.\d+\.\d+|(\w\.)+\w")]
        [string]$Address,

        [Parameter(Mandatory=$True,Position=1)]
        [alias('Credential')]
        [System.Management.Automation.PSCredential]$Cred
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
    }

    Process {
        $user = $cred.UserName.Replace("\","")
        $ApiKey = Get-WebRequestAsXML "https://$Address/api/?type=keygen&user=$user&password=$($cred.getnetworkcredential().password)"
        if ($ApiKey.response.status -eq "success") {
            $CurrentConnection = New-Object -TypeName PsObject -Property @{
                'Address' = $Address
                'APIKey' = $ApiKey.response.result.key
                'ConnectionString' = "https://$Address/api/?key=$($ApiKey.response.result.key)"
            }

            return $CurrentConnection
        }
        else {
            throw "$($FunctionName): $($ApiKey.response.result.msg)"
        }
    }
}