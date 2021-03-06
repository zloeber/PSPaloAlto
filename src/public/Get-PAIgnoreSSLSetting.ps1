function Get-PAIgnoreSSLSetting {
    <#
    .SYNOPSIS
    Retrieves the module-wide setting for ignoring invalid SSL certificates on firewalls.
    .DESCRIPTION
    Retrieves the module-wide setting for ignoring invalid SSL certificates on firewalls.
    .LINK
    https://github.com/zloeber/pspaloalto
    .EXAMPLE
    PS> Get-PAIgnoreSSLSetting
    .NOTES
    Author: Zachary Loeber
    #>

    [CmdletBinding()]
    param(
    )
    begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
    }
    end {
        $script:_IgnoreSSL
        Write-Verbose "$($FunctionName): End."
    }
}
