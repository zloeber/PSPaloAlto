function Get-PALastResponse {
	<#
	.SYNOPSIS
		Returns last xml response returned from an operation.
	.DESCRIPTION
		Returns last xml response returned from an operation.
	.EXAMPLE
		C:\PS> Get-PALastResponse
        
        Description
        -----------
        Shows last response from an operation.
 
    .OUTPUTS
        XML.XMLDocument
	#>
    [CmdletBinding()]
    Param ()

    return $script:LastResponse
}