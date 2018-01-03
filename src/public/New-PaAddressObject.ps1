function New-PaAddressObject {
	<#
    .SYNOPSIS
    Creates a new address object on the targeted PA.
    .DESCRIPTION
    Creates a new address object on the targeted PA.
    .EXAMPLE
    New-PaAddressObject -Name 'addr_ext_4.2.2.2' -IPNetmask '4.2.2.2' -Description 'Test Address Object'
    .PARAMETER Name
    Name of address object
    .PARAMETER IPNetmask
    IP netmask to set on the object
    .PARAMETER Description
    Description of address object
    .PARAMETER PaConnection
    Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .PARAMETER Target
    Configuration to target, either vsys1 (default) or panorama
	#>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [ValidateLength(1,31)]
        [string]$Name,
        [Parameter(position=1,Mandatory=$True)]
        [string]$IPNetmask,
        [Parameter(position=2)]
        [ValidateLength(0,255)]
        [string]$Description,
        [Parameter(position=3)]
        [PSObject]$PaConnection,
        [Parameter(position=4)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    # Pull in all the caller verbose,debug,info,warn and other preferences
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand

    Write-Verbose "$($FunctionName): Using parameter set $($PSCmdlet.ParameterSetName)"
    Write-Verbose ($PSBoundParameters | out-string)

    Set-PaAddressObject @PSBoundParameters
}