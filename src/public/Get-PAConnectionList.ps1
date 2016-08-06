function Get-PAConnectionList {
	<#
	.SYNOPSIS
		Returns list of connected Palo Altos.
	.DESCRIPTION
		Returns list of connected Palo Altos.
	.EXAMPLE
		C:\PS> Get-PAConnectionList
        
        Description
        -----------
        Shows all the stored api connection objects.
	#>
    [CmdletBinding()]
    Param ()

    return $script:PaConnectionArray
}