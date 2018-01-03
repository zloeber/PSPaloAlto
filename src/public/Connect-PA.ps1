function Connect-PA {
    <#
    .SYNOPSIS
    Creates connection string to a firewall for use with other functions in this module.
    .DESCRIPTION
    Creates connection string to a firewall for use with other functions in this module.
    .EXAMPLE
    PS> Connect-Pa -Address 192.168.1.1 -Cred $PSCredential -Append

    Creates a connection object to 192.168.1.1 using the credential stored in $PSCredential and adds it to the list of firewalls which will be processed.
    .PARAMETER Address
    Specifies the IP or FQDN of the system to connect to.
    .PARAMETER Cred
    Specifiy a PSCredential object, If no credential object is specified, the user will be prompted.
    .PARAMETER Append
    Append this connection to the list of connections in the array.
    #>
    [CmdletBinding()]
    Param (
        [Parameter( Mandatory=$True )]
        [string]$Address,

        [Parameter( Mandatory=$True, Position=1 )]
        [System.Management.Automation.PSCredential]$Cred,

        [Parameter( Position=2 )]
        [Switch]$Append
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
    }

    Process {
        try {
            $CurrentConnection = Get-PAConnectionString -Address $Address -Cred $Cred
            if ($Append) {
                # if we are adding to the list of connected PAs then add to the array if connectionstring is unique
                if (($script:PaConnectionArray).ConnectionString -notcontains $CurrentConnection.ConnectionString) {
                    $script:PaConnectionArray += $CurrentConnection
                }
            }
            else {
                # Otherwise just make this the only connection in the array
                $script:PaConnectionArray = @($CurrentConnection)
            }
        }
        catch {
            throw "$($FunctionName): Unable to connect to that Palo Alto Device!"
        }
    }
}