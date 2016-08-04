function Test-PaConnection {
    <#
    .SYNOPSIS
        Validates if the PA connection variable is set
    .DESCRIPTION
        Validates if the PA connection variable is set
    .EXAMPLE
        Test-PaConnection
    #>
    if ( -not ($Script:PaConnectionArray) ) {
        return $false
    } 
    else {
        return $true
    }
}