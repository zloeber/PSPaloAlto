function Get-PALastURL {
	<#
	.SYNOPSIS
		Returns last URL used for an operation.
	.DESCRIPTION
		Returns last URL used for an operation.
	.EXAMPLE
		C:\PS> Get-PALastURL
        
        Description
        -----------
        Shows last response from an operation.
 
    .OUTPUTS
        XML.XMLDocument
	#>
    [CmdletBinding()]
    Param ()

    return $script:LastURL
}