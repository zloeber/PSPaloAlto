## Pre-Loaded Module code ##

# Private Module Variables

# Array of our connected palo altos (well firewalls which we were able to generate a connection string for)
$PaConnectionArray = @()

# Stores the immediate URL that was used in the last XML call to the device
$LastURL = ''

# Stores the last result of an XML query to th device
$LastRepsponse = ''

# Used to track if SSL work around configuration is in place
$script:IsSSLWorkAroundInPlace = $false

#
$script:modCertCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback

## PRIVATE MODULE FUNCTIONS AND DATA ##

function Get-CallerPreference {
    <#
    .Synopsis
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]$SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]$Name
    )

    begin {
        $filterHash = @{}
    }
    
    process {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }

        foreach ($entry in $vars.GetEnumerator()) {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name))) {
                
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
                
                if ($null -ne $variable) {
                    if ($SessionState -eq $ExecutionContext.SessionState) {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered') {
            foreach ($varName in $filterHash.Keys) {
                if (-not $vars.ContainsKey($varName)) {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)
                
                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }
    }
}

function Get-ScriptPath {
	$scriptDir = Get-Variable PSScriptRoot -ErrorAction SilentlyContinue | ForEach-Object { $_.Value }
	if (!$scriptDir) {
		if ($MyInvocation.MyCommand.Path) {
			$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
		}
	}
	if (!$scriptDir) {
		if ($ExecutionContext.SessionState.Module.Path) {
			$scriptDir = Split-Path (Split-Path $ExecutionContext.SessionState.Module.Path)
		}
	}
	if (!$scriptDir) {
		$scriptDir = $PWD
	}
	
	return $scriptDir
}

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

<#
  Module file content:

  CmdLet Name                    Category                  Access modifier       Updated
  -----------                    --------                  ---------------       -------
  ConvertToNetworkObject         IP maths                  Private               14/01/2014
  ConvertTo-BinaryIP             IP maths                  Public                25/11/2010
  ConvertTo-DecimalIP            IP maths                  Public                25/11/2010
  ConvertTo-DottedDecimalIP      IP maths                  Public                25/11/2010
  ConvertTo-HexIP                IP maths                  Public                13/10/2011
  ConvertFrom-HexIP              IP maths                  Public                13/10/2011
  ConvertTo-MaskLength           IP maths                  Public                25/11/2010
  ConvertTo-Mask                 IP maths                  Public                25/11/2010
  ConvertTo-Subnet               IP maths                  Public                14/05/2014
  Get-BroadcastAddress           IP maths                  Public                25/11/2010
  Get-NetworkAddress             IP maths                  Public                25/11/2010
  Get-NetworkRange               IP maths                  Public                13/10/2011
  Get-NetworkSummary             IP maths                  Public                25/11/2010
  Get-Subnets                    IP maths                  Public                13/10/2011
  Test-SubnetMember              IP maths                  Public                12/08/2013
  Get-Manufacturer               MAC address tools         Public                08/05/2013
  Update-ManufacturerList        MAC address tools         Public                08/05/2013
  Test-TcpPort                   General testing           Public                25/11/2010
  Get-PublicIP                   General testing           Public                08/04/2014
  Test-Smtp                      SMTP                      Public                15/04/2014
  Get-WhoIs                      WhoIs                     Public                15/01/2014
#>

##############################################################################################################################################################
#                                                                     Parameter handling                                                                     #
##############################################################################################################################################################

function ConvertToNetworkObject {
  # .SYNOPSIS
  #   Converts IP address formats to a set a known styles.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   ConvertToNetworkObject ensures consistent values are recorded from parameters which must handle differing addressing formats. This CmdLet allows all other the other functions in this module to offload parameter handling.
  # .PARAMETER IPAddress
  #   Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubnetMask
  #   A subnet mask as an IP address.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   Indented.NetworkTools.NetworkObject
  
  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeLine = $true, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$IPAddress,
    
    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubnetMask
  )
 
  $NetworkObject = New-Object PsObject -Property ([Ordered]@{
    IPAddress  = $null;
    SubnetMask = $null;
    MaskLength = [Byte]0;
    State      = "No error";
  })
  $NetworkObject.PsObject.TypeNames.Add("Indented.NetworkTools.NetworkObject")
  
  # A bit of cleaning
  $IPAddress = $IPAddress.Trim()
  $SubnetMask = $SubnetMask.Trim()
  
  # Handling for IP and Mask as a single string
  if ($IPAddress -match '^(\S+)\s(\S+)$') {
    # Send it back into this function sort out the values now.
    return ConvertToNetworkObject $matches[1] $matches[2]
  }
  
  # IPAddress handling
  
  $IPAddressTest = New-Object IPAddress 0
  if ([IPAddress]::TryParse($IPAddress, [Ref]$IPAddressTest)) {
    if ($IPAddressTest.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
      $NetworkObject.IPAddress = $IPAddressTest
    } else {
      $NetworkObject.State = "Unexpected IPv6 address for IPAddress."
    }
  } elseif ($myinvocation.BoundParameters.ContainsKey("SubnetMask")) {
    $NetworkObject.State = "Invalid IP address format."
  } else {
    # Begin string parsing
    if ($IPAddress -match '^(?<IPAddress>(?:[0-9]{1,2}|[0-1][0-9]{2}|2[0-4][0-9]|25[0-5])(?:\.(?:[0-9]{1,2}|[0-1][0-9]{2}|2[0-4][0-9]|25[0-5])){0,3})[\\/](?<SubnetMask>\d+)$') {
      # Fix up the IP address
      $IPAddressBuilder = [Array]($matches.IPAddress -split '\.' | ForEach-Object { [Byte]$_ })
      while ($IPAddressBuilder.Count -lt 4) {
        $IPAddressBuilder += 0
      }

      if ([IPAddress]::TryParse(($IPAddressBuilder -join '.'), [Ref]$IPAddressTest)) {
        $NetworkObject.IPAddress = $IPAddressTest
      } else {
        $NetworkObject.State = "Matched regular expression, but still failed to convert. Unexpected error."
      }
     
      # Hold this for a moment or two.
      [Byte]$MaskLength = $matches.SubnetMask
    } else {
      $NetworkObject.State = "Invalid CIDR notation format."
    }
  }

  # SubnetMask handling  
  
  # Validate cannot be (easily) done using a regular expression. Hard-coding this as a string comparison should be nice and fast.
  $ValidSubnetMaskValues = "0.0.0.0", "128.0.0.0", "192.0.0.0", "224.0.0.0", "240.0.0.0", "248.0.0.0", "252.0.0.0", "254.0.0.0", "255.0.0.0",
    "255.128.0.0", "255.192.0.0", "255.224.0.0", "255.240.0.0", "255.248.0.0", "255.252.0.0", "255.254.0.0", "255.255.0.0",
    "255.255.128.0", "255.255.192.0", "255.255.224.0", "255.255.240.0", "255.255.248.0", "255.255.252.0", "255.255.254.0", "255.255.255.0",
    "255.255.255.128", "255.255.255.192", "255.255.255.224", "255.255.255.240", "255.255.255.248", "255.255.255.252", "255.255.255.254", "255.255.255.255"
  
  if ($myinvocation.BoundParameters.ContainsKey("SubnetMask") -and $NetworkObject.State -eq "No Error") {
    if ([IPAddress]::TryParse($SubnetMask, [Ref]$IPAddressTest)) {
      if ($IPAddressTest.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
        if ($IPAddressTest.ToString() -notin $ValidSubnetMaskValues) {
          $NetworkObject.State = "Invalid subnet mask value."
        } else {
          $NetworkObject.SubnetMask = $IPAddressTest
        }
      } else {
        $NetworkObject.State = "Unexpected IPv6 address for SubnetMask."
      }
    } else {
      $NetworkObject.State = "Invalid subnet mask format."
    }
  } elseif ($NetworkObject.State -eq "No error") {
    if ($MaskLength -eq $null) {
      # Default the length to 32 bits.
      $NetworkObject.MaskLength = 32
    } elseif ($MaskLength -ge 0 -and $MaskLength -le 32) {
      $NetworkObject.MaskLength = $MaskLength
    } else {
      $NetworkObject.State = "Mask length out of range (expecting 0 to 32)."
    }
  }
  
  return $NetworkObject
}

##############################################################################################################################################################
#                                                                          IP maths                                                                          #
##############################################################################################################################################################

function ConvertTo-BinaryIP {
  # .SYNOPSIS
  #   Converts a Decimal IP address into a binary format.
  # .DESCRIPTION
  #   ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format. The output from this function is dotted binary.
  # .PARAMETER IPAddress
  #   An IP Address to convert.
  # .INPUTS
  #   System.Net.IPAddress
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   ConvertTo-BinaryIP 1.2.3.4
  #    
  #   Convert an IP address to a binary format.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [IPAddress]$IPAddress
  )

  process {  
    return ($IPAddress.GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }) -join '.'
  }
}

function ConvertTo-DecimalIP {
  # .SYNOPSIS
  #   Converts a Decimal IP address into a 32-bit unsigned integer.
  # .DESCRIPTION
  #   ConvertTo-DecimalIP takes a decimal IP, uses a shift operation on each octet and returns a single UInt32 value.
  # .PARAMETER IPAddress
  #   An IP Address to convert.
  # .INPUTS
  #   System.Net.IPAddress
  # .OUTPUTS
  #   System.UInt32
  # .EXAMPLE
  #   ConvertTo-DecimalIP 1.2.3.4
  #   
  #   Converts an IP address to an unsigned 32-bit integer value.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [IPAddress]$IPAddress
  )

  process {
    $i = 3; $DecimalIP = 0;
    $IPAddress.GetAddressBytes() | ForEach-Object { $DecimalIP += [UInt32]$_ -shl (8 * $i); $i-- }

    return [UInt32]$DecimalIP
  }
}

function ConvertTo-DottedDecimalIP {
  # .SYNOPSIS
  #   Converts either an unsigned 32-bit integer or a dotted binary string to an IP Address.
  # .DESCRIPTION
  #   ConvertTo-DottedDecimalIP uses a regular expression match on the input string to convert to an IP address.
  # .PARAMETER IPAddress
  #   A string representation of an IP address from either UInt32 or dotted binary.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   ConvertTo-DottedDecimalIP 11000000.10101000.00000000.00000001
  #    
  #   Convert the binary form back to dotted decimal, resulting in 192.168.0.1.
  # .EXAMPLE
  #   ConvertTo-DottedDecimalIP 3232235521
  #    
  #   Convert the decimal form back to dotted decimal, resulting in 192.168.0.1.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]$IPAddress
  )
  
  process {
    switch -regex ($IPAddress) {
      "([01]{8}\.){3}[01]{8}" {
        return [IPAddress]([String]::Join('.', $( $IPAddress -split '\.' | ForEach-Object { [Convert]::ToUInt32($_, 2) } )))
      }
      "\d" {
        $IPAddress = [UInt32]$IPAddress
        $DottedIP = 3..0 | ForEach-Object {
          $Remainder = $IPAddress % [Math]::Pow(256, $_)
          ($IPAddress - $Remainder) / [Math]::Pow(256, $_)
          $IPAddress = $Remainder
         }
       
        return [IPAddress]($DottedIP -join '.')
      }
      default {
        Write-Error "ConvertTo-DottedDecimalIP: Cannot convert this format"
      }
    }
  }
}

function ConvertTo-HexIP {
  # .SYNOPSIS
  #   Convert a dotted decimal IP address into a hexadecimal string.
  # .DESCRIPTION
  #   ConvertTo-HexIP takes a dotted decimal IP and returns a single hexadecimal string value.
  # .PARAMETER IPAddress
  #   An IP Address to convert.
  # .INPUTS
  #    System.Net.IPAddress
  # .OUTPUTS
  #    System.String
  # .EXAMPLE
  #   ConvertTo-HexIP 192.168.0.1
  #    
  #   Returns the hexadecimal string c0a80001.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [IPAddress]$IPAddress
  )

  process {
    return ($IPAddress.GetAddressBytes() | ForEach-Object { '{0:x2}' -f $_ }) -join ''
  }
}

function ConvertFrom-HexIP {
  # .SYNOPSIS
  #   Converts a hexadecimal IP address into a dotted decimal string.
  # .DESCRIPTION
  #   ConvertFrom-HexIP takes a hexadecimal string and returns a dotted decimal IP address. An intermediate call is made to ConvertTo-DottedDecimalIP.
  # .PARAMETER IPAddress
  #   An IP Address to convert.
  # .INPUTS
  #    System.String
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   ConvertFrom-HexIP c0a80001
  #
  #   Returns the IP address 192.168.0.1.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidatePattern('^[0-9a-f]{8}$')]
    [String]$IPAddress
  )

  process {
    return ConvertTo-DottedDecimalIP ([Convert]::ToUInt32($IPAddress, 16))
  }
}

function ConvertTo-MaskLength {
  # .SYNOPSIS
  #   Convert a dotted-decimal subnet mask to a mask length.
  # .DESCRIPTION
  #   A simple count of the number of 1's in a binary string.
  # .PARAMETER SubnetMask
  #   A subnet mask to convert into length.
  # .INPUTS
  #   System.Net.IPAddress
  # .OUTPUTS
  #   System.Int32
  # .EXAMPLE
  #   ConvertTo-MaskLength 255.255.255.0
  #
  #   Returns 24, the length of the mask in bits.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Alias("Mask")]
    [IPAddress]$SubnetMask
  )

  process {
    $Params = ConvertToNetworkObject 0 $SubnetMask
    if ($Params.State -ne "No error") {
      Write-Error $Params.State -Category InvalidArgument
      return
    }
    
    $Bits = (($SubnetMask.GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2) }) -join '') -replace '0'

    return $Bits.Length
  }
}

function ConvertTo-Mask {
  # .SYNOPSIS
  #   Convert a mask length to a dotted-decimal subnet mask.
  # .DESCRIPTION
  #   ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging between 0 and 32. ConvertTo-Mask creates a binary string from the length, converts the string to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.
  # .PARAMETER MaskLength
  #   The number of bits which must be masked.
  # .INPUTS
  #   System.Int32
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   ConvertTo-Mask 24
  #
  #   Returns the dotted-decimal form of the mask, 255.255.255.0.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Alias("Length")]
    [ValidateRange(0, 32)]
    [Byte]$MaskLength
  )
  
  process {
    return ConvertTo-DottedDecimalIP ([Convert]::ToUInt32($(("1" * $MaskLength).PadRight(32, "0")), 2))
  }
}

function ConvertTo-Subnet {
  # .SYNOPSIS
  #   Convert a start and end IP address to the closest matching subnet.
  # .DESCRIPTION
  #   ConvertTo-Subnet attempts to convert a starting and ending IP address from a range to the closest subnet.
  # .PARAMETER Start
  #   The first IP address from a range.
  # .PARAMETER End
  #   The last IP address from a range.
  # .INPUTS
  #   System.Net.IPAddress
  # .OUTPUTS
  #   Indented.NetworkTools.NetworkSummary
  # .EXAMPLE
  #   ConvertTo-Subnet 0.0.0.0 255.255.255.255
  # .EXAMPLE
  #   ConvertTo-Subnet 192.168.0.1 192.168.0.129
  # .EXAMPLE
  #   ConvertTo-Subnet 10.0.0.1 11.0.0.1
  # .EXAMPLE
  #   ConvertTo-Subnet 10.0.0.126 10.0.0.129
  # .EXAMPLE
  #   ConvertTo-Subnet 10.0.0.128 10.0.0.128
  # .EXAMPLE
  #   ConvertTo-Subnet 10.0.0.128 10.0.0.130
 
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IPAddress]$Start,

    [Parameter(Mandatory = $true)]
    [IPAddress]$End
  )

  if ($Start -eq $End) {
    return (Get-NetworkSummary "$Start\32")
  }

  $DecimalStart = ConvertTo-DecimalIP $Start
  $DecimalEnd = ConvertTo-DecimalIP $End

  $i = 32
  do {
    $i--
  } until (($DecimalStart -band ([UInt32]1 -shl $i)) -ne ($DecimalEnd -band ([UInt32]1 -shl $i)))
  return (Get-NetworkSummary "$Start\$(32 - $i - 1)")
}

function Get-BroadcastAddress {
  # .SYNOPSIS
  #   Get the broadcast address for a network range.
  # .DESCRIPTION
  #   Get-BroadcastAddress returns the broadcast address for a subnet by performing a bitwise AND operation against the decimal forms of the IP address and inverted subnet mask.
  # .PARAMETER IPAddress
  #   Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubnetMask
  #   A subnet mask as an IP address.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   Get-BroadcastAddress 192.168.0.243 255.255.255.0
  #   
  #   Returns the address 192.168.0.255.
  # .EXAMPLE
  #   Get-BroadcastAddress 10.0.9/22
  #   
  #   Returns the address 10.0.11.255.
  # .EXAMPLE
  #   Get-BroadcastAddress 0/0
  #
  #   Returns the address 255.255.255.255.
  # .EXAMPLE
  #   Get-BroadcastAddress "10.0.0.42 255.255.255.252"
  #
  #   Input values are automatically split into IP address and subnet mask. Returns the address 10.0.0.43.
  
  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$IPAddress,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubnetMask
  )

  process {
    $Params = ConvertToNetworkObject "$IPAddress $SubnetMask"
    if ($Params.State -ne "No error") {
      Write-Error $Params.State -Category InvalidArgument
      return
    } elseif (-not $Params.SubnetMask) {
      $Params.SubnetMask = ConvertTo-Mask $Params.MaskLength
    }

    return ConvertTo-DottedDecimalIP $((ConvertTo-DecimalIP $Params.IPAddress) -bor ((-bnot (ConvertTo-DecimalIP $Params.SubnetMask)) -band [UInt32]::MaxValue))
  }
}

function Get-NetworkAddress {
  # .SYNOPSIS
  #   Get the network address for a network range.
  # .DESCRIPTION
  #   Get-NetworkAddress returns the network address for a subnet by performing a bitwise AND operation against the decimal forms of the IP address and subnet mask. Get-NetworkAddress expects both the IP address and subnet mask in dotted decimal format.
  # .PARAMETER IPAddress
  #   Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubnetMask
  #   A subnet mask as an IP address.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   Get-NetworkAddress 192.168.0.243 255.255.255.0
  #    
  #   Returns the address 192.168.0.0.
  # .EXAMPLE
  #   Get-NetworkAddress 10.0.9/22
  #   
  #   Returns the address 10.0.8.0.
  # .EXAMPLE
  #   Get-NetworkAddress "10.0.23.21 255.255.255.224"
  #
  #   Input values are automatically split into IP address and subnet mask. Returns the address 10.0.23.0.
  
  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$IPAddress,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubnetMask
  )

  process {
    $Params = ConvertToNetworkObject "$IPAddress $SubnetMask"
    if ($Params.State -ne "No error") {
      Write-Error $Params.State -Category InvalidArgument
      return
    } elseif (-not $Params.SubnetMask) {
      $Params.SubnetMask = ConvertTo-Mask $Params.MaskLength
    }
  
    return ConvertTo-DottedDecimalIP ((ConvertTo-DecimalIP $Params.IPAddress) -band (ConvertTo-DecimalIP $Params.SubnetMask))
  }
}

function Get-NetworkRange {
  # .SYNOPSIS
  #   Get a list of IP addresses within the specified network.
  # .DESCRIPTION
  #   Get-NetworkRange finds the network and broadcast address as decimal values then starts a counter between the two, returning IPAddress for each.
  # .PARAMETER IPAddress
  #   Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubnetMask
  #   A subnet mask as an IP address.
  # .INPUTS
  #   System.Net.IPAddress
  #   System.String
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   Get-NetworkRange 192.168.0.0 255.255.255.0
  #
  #   Returns all IP addresses in the range 192.168.0.0/24.
  # .EXAMPLE
  #   Get-NetworkRange 10.0.8.0/22
  #
  #   Returns all IP addresses in the range 192.168.0.0 255.255.252.0.

  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$IPAddress,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubnetMask
  )

  process {
    $Params = ConvertToNetworkObject "$IPAddress $SubnetMask"
    if ($Params.State -ne "No error") {
      Write-Error $Params.State -Category InvalidArgument
      return
    } elseif (-not $Params.SubnetMask) {
      $Params.SubnetMask = ConvertTo-Mask $Params.MaskLength
    }
  
    $DecimalIP = ConvertTo-DecimalIP $Params.IPAddress
    $DecimalMask = ConvertTo-DecimalIP $Params.SubnetMask
  
    $DecimalNetwork = $DecimalIP -band $DecimalMask
    $DecimalBroadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)

    for ($i = $($DecimalNetwork + 1); $i -lt $DecimalBroadcast; $i++) {
      ConvertTo-DottedDecimalIP $i
    }
  }
}

function Get-NetworkSummary {
  # .SYNOPSIS
  #   Generates a summary describing several properties of a network range
  # .DESCRIPTION
  #   Get-NetworkSummary uses many of the IP conversion CmdLets to provide a summary of a network range from any IP address in the range and a subnet mask.
  # .PARAMETER IPAddress
  #   Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubnetMask
  #   A subnet mask as an IP address.
  # .INPUTS
  #   System.Net.IPAddress
  #   System.String
  # .OUTPUTS
  #   System.Object
  # .EXAMPLE
  #   Get-NetworkSummary 192.168.0.1 255.255.255.0
  # .EXAMPLE
  #   Get-NetworkSummary 10.0.9.43/22
  # .EXAMPLE
  #   Get-NetworkSummary 0/0

  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$IPAddress,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubnetMask
  )

  process {
    $Params = ConvertToNetworkObject "$IPAddress $SubnetMask"
    if ($Params.State -ne "No error") {
      Write-Error $Params.State -Category InvalidArgument
      return
    } elseif (-not $Params.SubnetMask) {
      $Params.SubnetMask = ConvertTo-Mask $Params.MaskLength
    }
    
    $DecimalIP = ConvertTo-DecimalIP $Params.IPAddress
    $DecimalMask = ConvertTo-DecimalIP $Params.SubnetMask
    $DecimalNetwork =  $DecimalIP -band $DecimalMask
    $DecimalBroadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)
  
    $NetworkSummary = New-Object PSObject -Property ([Ordered]@{
      NetworkAddress    = (ConvertTo-DottedDecimalIP $DecimalNetwork);
      NetworkDecimal    = $DecimalNetwork
      BroadcastAddress  = (ConvertTo-DottedDecimalIP $DecimalBroadcast);
      BroadcastDecimal  = $DecimalBroadcast
      Mask              = $Params.SubnetMask;
      MaskLength        = (ConvertTo-MaskLength $Params.SubnetMask);
      MaskHexadecimal   = (ConvertTo-HexIP $Params.SubnetMask);
      HostRange         = "";
      NumberOfAddresses = ($DecimalBroadcast - $DecimalNetwork + 1)
      NumberOfHosts     = ($DecimalBroadcast - $DecimalNetwork - 1);
      Class             = "";
      IsPrivate         = $false
    })
    $NetworkSummary.PsObject.TypeNames.Add("Indented.NetworkTools.NetworkSummary")

    if ($NetworkSummary.NumberOfHosts -lt 0) {
      $NetworkSummary.NumberOfHosts = 0
    }
    if ($NetworkSummary.MaskLength -lt 31) {
      $NetworkSummary.HostRange = [String]::Format("{0} - {1}",
        (ConvertTo-DottedDecimalIP ($DecimalNetwork + 1)),
        (ConvertTo-DottedDecimalIP ($DecimalBroadcast - 1)))
    }
  
    switch -regex (ConvertTo-BinaryIP $Params.IPAddress) {
      "^1111"              { $NetworkSummary.Class = "E"; break }
      "^1110"              { $NetworkSummary.Class = "D"; break }
      "^11000000.10101000" { $NetworkSummary.Class = "C"; if ($NetworkSummary.MaskLength -ge 16) { $NetworkSummary.IsPrivate = $true }; break }
      "^110"               { $NetworkSummary.Class = "C" }
      "^10101100.0001"     { $NetworkSummary.Class = "B"; if ($NetworkSummary.MaskLength -ge 12) { $NetworkSummary.IsPrivate = $true }; break }
      "^10"                { $NetworkSummary.Class = "B"; break }
      "^00001010"          { $NetworkSummary.Class = "A"; if ($NetworkSummary.MaskLength -ge 8) { $NetworkSummary.IsPrivate = $true}; break }
      "^0"                 { $NetworkSummary.Class = "A"; break }
    }   
  
    return $NetworkSummary
  }
}

function Get-Subnets {
  # .SYNOPSIS
  #   Get a list of subnets of a given size within a defined supernet.
  # .DESCRIPTION
  #   Generates a list of subnets for a given network range using either the address class or a user-specified value.
  # .PARAMETER NetworkAddress
  #   Any address in the super-net range. Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubnetMask
  #   The desired mask, determines the size of the resulting subnets. Must be a valid subnet mask.
  # .PARAMETER SupernetLength
  #   By default Get-Subnets uses the address class to determine the size of the supernet. Where the supernet describes the range of addresses being split.
  # .INPUTS
  #   System.String
  #   System.UInt32
  # .OUTPUTS
  #   System.Object[]
  # .EXAMPLE
  #   Get-Subnets 10.0.0.0 255.255.255.192 -SupernetLength 24
  #   
  #   4 /26 networks are returned.
  # .EXAMPLE
  #   Get-Subnets 10.0.0.0 255.255.0.0
  #   
  #   The supernet size is assumed to be 8, the mask length for a class A network. 256 /16 networks are returned.
  # .EXAMPLE
  #   Get-Subnets 0/8 -SupernetLength 0

  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$NetworkAddress,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubnetMask,
    
    [ValidateRange(0, 32)]
    [UInt32]$SupernetLength
  )

  process {
    $Params = ConvertToNetworkObject "$NetworkAddress $SubnetMask"
    if ($Params.State -ne "No error") {
      Write-Error $Params.State -Category InvalidArgument
      return
    } elseif (-not $Params.SubnetMask) {
      $Params.SubnetMask = ConvertTo-Mask $Params.MaskLength
    } elseif ($Params.MaskLength -eq 0) {
      $Params.MaskLength = ConvertTo-MaskLength $Params.SubnetMask
    }
    
    if (-not $myinvocation.BoundParameters.ContainsKey("SupernetLength")) {
      $SupernetLength = switch -regex (ConvertTo-BinaryIP $Params.IPAddress) {
        "^110"  { 24 }
        "^10"   { 16 }
        "^0"    { 8 }
        default { 24 }
      }
    }
    
    if ($SupernetLength -gt $Params.MaskLength) {
      Write-Error "Subnet is larger than supernet. Aborting"
      return
    }

    $NumberOfNets = [Math]::Pow(2, ($Params.MaskLength - $SupernetLength))
    $NumberOfAddresses = [Math]::Pow(2, (32 - $Params.MaskLength))

    $DecimalAddress = ConvertTo-DecimalIP (Get-NetworkAddress "$($Params.IPAddress)/$SupernetLength")
    for ($i = 0; $i -lt $NumberOfNets; $i++) {
      $NetworkAddress = ConvertTo-DottedDecimalIP $DecimalAddress 

      $Subnet = New-Object PsObject -Property ([Ordered]@{
        NetworkAddress   = $NetworkAddress;
        BroadcastAddress = (Get-BroadcastAddress $NetworkAddress $Params.SubnetMask);
        SubnetMask       = $Params.SubnetMask;
        SubnetLength     = $Params.MaskLength;
        HostAddresses    = $(
          $NumberOfHosts = $NumberOfAddresses - 2
          if ($NumberOfHosts -lt 0) { 0 } else { $NumberOfHosts }
        );
      })
      $Subnet.PsObject.TypeNames.Add("Indented.NetworkTools.Subnet")
      
      $Subnet
      
      $DecimalAddress += $NumberOfAddresses
    }
  }
}

function Test-SubnetMember {
  # .SYNOPSIS
  #   Tests an IP address to determine if it falls within IP address range.
  # .DESCRIPTION
  #   Test-SubnetMember attempts to determine whether or not an address or range falls within another range. The network and broadcast address are calculated the converted to decimal then compared to the decimal form of the submitted address.
  # .PARAMETER ObjectIPAddress
  #   A representation of the object, the network to test against. Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER ObjectSubnetMask
  #   A subnet mask as an IP address.
  # .PARAMETER SubjectIPAddress
  #   A representation of the subject, the network to be tested. Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
  # .PARAMETER SubjectSubnetMask
  #   A subnet mask as an IP address.
  # .INPUTS
  #    System.String
  # .OUTPUTS
  #    System.Boolean
  # .EXAMPLE
  #   Test-SubnetMember -SubjectIPAddress 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/16
  #    
  #   Returns true as the subject network can be contained within the object network.
  # .EXAMPLE
  #   Test-SubnetMember -SubjectIPAddress 192.168.0.0/16 -ObjectIPAddress 192.168.0.0/24
  #    
  #   Returns false as the subject network is larger the object network.
  # .EXAMPLE
  #   Test-SubnetMember -SubjectIPAddress 10.2.3.4/32 -ObjectIPAddress 10.0.0.0/8
  #    
  #   Returns true as the subject IP address is within the object network.
  # .EXAMPLE
  #   Test-SubnetMember -SubjectIPAddress 255.255.255.255 -ObjectIPAddress 0/0
  #
  #   Returns true as the subject IP address is the last in the object network range.

  [CmdLetBinding(DefaultParameterSetName = 'CIDRNotation')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'IPAndMask')]
    [String]$SubjectIPAddress,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'IPAndMask')]
    [String]$SubjectSubnetMask,
    
    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'CIDRNotation')]
    [Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'IPAndMask')]
    [String]$ObjectIPAddress,

    [Parameter(Mandatory = $true, Position = 4, ParameterSetName = 'IPAndMask')]
    [String]$ObjectSubnetMask
  )

  $SubjectParams = ConvertToNetworkObject "$SubjectIPAddress $SubjectSubnetMask"
  if ($SubjectParams.State -ne "No error") {
    Write-Error "Subject: $($SubjectParams.State)" -Category InvalidArgument
    return
  } elseif (-not $SubjectParams.SubnetMask) {
    $SubjectParams.SubnetMask = ConvertTo-Mask $SubjectParams.MaskLength
  }

  $ObjectParams = ConvertToNetworkObject "$ObjectIPAddress $ObjectSubnetMask"
  if ($ObjectParams.State -ne "No error") {
    Write-Error "Object: $($ObjectParams.State)" -Category InvalidArgument
    return
  } elseif (-not $ObjectParams.SubnetMask) {
    $ObjectParams.SubnetMask = ConvertTo-Mask $ObjectParams.MaskLength
  }
  
  # A simple check, if the mask is shorter (larger network) then it won't be a subnet of the object anyway.
  if ($SubjectParams.MaskLength -lt $ObjectParams.MaskLength) {
    return $false
  }
  
  $SubjectDecimalIP = ConvertTo-DecimalIP $SubjectParams.IPAddress
  $ObjectDecimalNetwork = ConvertTo-DecimalIP (Get-NetworkAddress "$($ObjectParams.IPAddress) $($ObjectParams.SubnetMask)")
  $ObjectDecimalBroadcast = ConvertTo-DecimalIP (Get-BroadcastAddress "$($ObjectParams.IPAddress) $($ObjectParams.SubnetMask)")
  
  # If the mask is longer (smaller network), then the decimal form of the address must be between the 
  # network and broadcast address of the object (the network we test against).
  if ($SubjectDecimalIP -ge $ObjectDecimalNetwork -and $SubjectDecimalIP -le $ObjectDecimalBroadcast) {
    return $true
  } else {
    return $false
  }
}

##############################################################################################################################################################
#                                                                      MAC address tools                                                                     #
##############################################################################################################################################################

function Get-Manufacturer {
  # .SYNOPSIS
  #   Get the manufacturer associated with a MAC address.
  # .DESCRIPTION
  #   Get-Manufacturer attempts to find a manufacturer for a given MAC address. The list of manufacturers is cached locally in XML format, the function Update-ManufacturerList is used to populate and update the cached list.
  # .PARAMETER MACAddress
  #   A full MAC address, with or without delimiters. Accepted delimiters are ., - and :.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Object
  # .EXAMPLE
  #   Get-Manufacturer 00:00:00:00:00:01
  # .EXAMPLE
  #   Get-Manufacturer 000000000001
  # .EXAMPLE
  #   Get-Manufacturer 00-00-00-00-00-01
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeLine = $true, ValueFromPipelineByPropertyname = $true)]
    [ValidatePattern('^([0-9A-Z]{2}[.\-:]?){5}([0-9A-Z]{2})$')]
    [String]$MACAddress
  )
  
  process {
    $MACAddress -match '([0-9A-Z]{2})[.\-:]?([0-9A-Z]{2})[.\-:]?([0-9A-Z]{2})' | Out-Null
    $OUI = [String]::Format("{0}-{1}-{2}", $matches[1], $matches[2], $matches[3]).ToUpper()
  
    $FilePath = "$psscriptroot\oui.xml"

    if (Test-Path $FilePath) {
      $XPathDocument = New-Object Xml.XPath.XPathDocument($FilePath)
      $XPathNavigator = $XPathDocument.CreateNavigator()

      $XPathExpression = $XPathNavigator.Compile("/manufacturers/manufacturer[oui='$OUI']")

      $XPathNavigator.Select($XPathExpression) | ForEach-Object {
        $ReturnObject = New-Object Object
        # Property: MACAddress
        $ReturnObject | Add-Member MACAddress -MemberType NoteProperty -Value $MACAddress
        $_.Select("./*") | ForEach-Object {
          # Property: <ValueFromXML>
          Add-Member ([Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($_.Name)) -MemberType NoteProperty -Value $_.TypedValue -InputObject $ReturnObject
        }
        $ReturnObject
      }
    } else {
      Write-Warning "Get-Manufacturer: The manufacturer list does not exist. Run Update-ManufacturerList to create."
    }
  }
}

function Update-ManufacturerList {
  # .SYNOPSIS
  #   Updates the cached manufacturer list maintained by the IEEE.
  # .DESCRIPTION
  #   Update-ManufacturerList attempts to download the assigned list of MAC address prefixes using Get-WebContent.
  #    
  #   The return is converted into an XML format to act as the cache file for Get-Manufacturer.
  # .PARAMETER Source
  #    By default, the manufacturer list is downloaded from http://standards.ieee.org/develop/regauth/oui/oui.txt. An alternate source may be specified if required.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Update-ManufacturerList
  
  [CmdLetBinding()]
  param(
    [String]$Source = "http://standards.ieee.org/develop/regauth/oui/oui.txt"
  )
 
  $Writer = New-Object IO.StreamWriter("$psscriptroot\oui.xml")
  $Writer.WriteLine("<?xml version='1.0'?>")
  $Writer.WriteLine("<manufacturers>")
  
  Get-WebContent $Source | ForEach-Object {
    switch -regex ($_) {
      '^\s*([0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2})\s+\(hex\)[\s\t]*(.+)$' {
        $OUI = $matches[1]
        $Organisation = $matches[2]
        break
      }
      '^\s*([0-9A-F]{6})\s+\(base 16\)[\s\t]*(.+)$' { 
        $CompanyID = $matches[1]
        [Array]$Address = $matches[2]
        break
      }
      '^\s+(\S+.+)$' {
        $Address += $matches[1]
        break
      }
      '^\s*$' {
        if ($OUI -and $Organisation) {
          $Writer.WriteLine("<manufacturer>")
          $Writer.WriteLine("<oui>$OUI</oui>")
          $Writer.WriteLine("<organisation><![CDATA[$Organisation]]></organisation>")
          $Writer.WriteLine("<companyid>$CompanyID</companyid>")
          $Writer.WriteLine("<address><![CDATA[$($Address -join ', ')]]></address>")
          $Writer.WriteLine("</manufacturer>")
        }
        $OUI = $null; $Organisation = $null; $CompanyID = $null; $Address = $null
      }
    }
  }
  $Writer.WriteLine("</manufacturers>")
  $Writer.Close()
}

##############################################################################################################################################################
#                                                                      General testing                                                                       #
##############################################################################################################################################################

function Test-TcpPort {
  # .SYNOPSIS
  #   Test a TCP Port using System.Net.Sockets.TcpClient.
  # .DESCRIPTION
  #   Test-TcpPort establishes a TCP connection to the sepecified port then immediately closes the connection, returning whether or not the connection succeeded.
  #       
  #   This function fully opens TCP connections (3-way handshake), it does not half-open connections.
  # .PARAMETER IPAddress
  #   An IP address for the target system.
  # .PARAMETER Port
  #   The port number to connect to (between 1 and 655535).
  # .EXAMPLE
  #   Test-TcpPort 10.0.0.1 3389
  #
  #   Opens a TCP connection to 10.0.0.1 using port 3389.
  # .INPUTS
  #   System.Net.IPAddress
  #   System.UInt16
  # .OUTPUTS
  #   System.Boolean

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IPAddress]$IPAddress,
    
    [Parameter(Mandatory = $true)]
    [UInt16]$Port
  )

  $TcpClient = New-Object Net.Sockets.TcpClient
  try { $TcpClient.Connect($IPAddress, $Port) } catch { }
  if ($?) {
    $TcpClient.Close()
    return $true
  }
  return $false
}

function Get-PublicIP {
  # .SYNOPSIS
  #   Get information the current public IP address used by the client.
  # .DESCRIPTION
  #   Get-PublicIP makes a web request to a fixed URL which responds with the connecting client IP address.
  #
  #   This information is typically only required by clients operating behind a firewall or router performing NAT (Network Address Translation).
  # .OUTPUTS
  #   System.Net.IPAddress
  # .EXAMPLE
  #   Get-PublicIP
  
  [CmdLetBinding()]
  param( )
  
  return [IPAddress](Get-WebContent "http://www.indented.co.uk/utility/ip.php")[0]
}

##############################################################################################################################################################
#                                                                            SMTP                                                                            #
##############################################################################################################################################################

function Test-Smtp {
  # .SYNOPSIS
  #   Executes a simple SMTP conversation to test an SMTP service.
  # .DESCRIPTION
  #   Test-Smtp attemps to send an e-mail message using the specific SMTP service.
  # .PARAMETER From
  #   A sender address.
  # .PARAMETER IPAddress
  #   The server to connect to.
  # .PARAMETER Port
  #   The TCP Port to use. By default, Port 25 is used.
  # .PARAMETER To
  #   The recipient of the test e-mail.
  # .INPUTS
  #   System.Net.IPAddress
  #   System.String
  #   System.UInt32
  # .OUTPUTS
  #   System.Object

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IPAddress]$IPAddress,
    
    [UInt16]$Port = 25,

    [Parameter(Mandatory = $true)]
    [String]$To,
    
    [Parameter(Mandatory = $true)]
    [String]$From
  )

  $CommandList = "helo there", "mail from: <$From>", "rcpt to: <$To>", "data", "Subject: Test message from Test-Smtp: $(Get-Date)`r`n."

  $Socket = New-Socket
  try {
    Connect-Socket $Socket -RemoteIPAddress $IPAddress -RemotePort $Port
  } catch [Net.Sockets.SocketException] {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object Net.Sockets.SocketException ($_.Exception.InnerException.NativeErrorCode)),
      "Connection to $IPAddress failed",
      [Management.Automation.ErrorCategory]::ConnectionError,
      $Socket)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
  
  New-Object PsObject -Property ([Ordered]@{
    Operation = "RECEIVE";
    Data = (Receive-Bytes $Socket | ConvertTo-String);
  })

  # Send the remaining commands (terminated with CRLF, `r`n) and get the response
  $CommandList | ForEach-Object {
    New-Object PsObject -Property ([Ordered]@{
      Operation = "SEND";
      Data = $_;
    })
 
    Send-Bytes $Socket -Data (ConvertTo-Byte "$_`r`n")

    New-Object PsObject -Property ([Ordered]@{
      Operation = "RECEIVE";
      Data = (Receive-Bytes $Socket | ConvertTo-String);
    })
  }
  Disconnect-Socket $Socket
  Remove-Socket $Socket
}

##############################################################################################################################################################
#                                                                           WhoIs                                                                            #
##############################################################################################################################################################

function Get-WhoIs {
  # .SYNOPSIS
  #   Get a WhoIs record using servers published via whois-servers.net.
  # .DESCRIPTION
  #   For IP lookups, Get-WhoIs uses whois.arin.net as a starting point, chasing referrals within the record to get to an authoritative answer.
  # 
  #   For name lookups, Get-WhoIs uses the whois-servers.net service to attempt to locate a whois server for the top level domain (TLD).
  #      
  #   Get-WhoIs connects directly to whois servers using TCP/43.
  # .PARAMETER Name
  #   The name or IP address to locate the WhoIs record for.
  # .PARAMETER WhoIsServer
  #   A WhoIs server to use for the query. Dynamically populated, but can be overridden.
  # .PARAMETER Command
  #   A command to execute on the WhoIs server if the server requires a command prefixing before the query.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   Get-WhoIs indented.co.uk
  # .EXAMPLE
  #   Get-WhoIs 10.0.0.1

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name,
    
    [String]$WhoIsServer,

    [String]$Command
  )
 
  if (-not $WhoIsServer) {
    if ([IPAddress]::TryParse($Name, [Ref]$null) -or $Name.EndsWith("arpa")) {
      $WhoIsServer = $WhoIsServerName = "whois.arin.net"
      $Command = "n "
    } else {
      $WhoIsServer = $WhoIsServerName = "$($Name.Split('.')[-1]).whois-servers.net"
    }
  }
  if (-not ([Net.IPAddress]::TryParse($WhoIsServer, [Ref]$null))) {
    $WhoIsServerRecord = [Net.Dns]::GetHostEntry($WhoIsServer) |
      Select-Object -Expand AddressList |
      Select-Object -First 1
    $WhoIsServer = $WhoIsServerRecord.IPAddressToString
  }
  
  if ($WhoIsServer) {
    Write-Verbose "Get-WhoIs: Asking $WhoIsServerName ($WhoIsServer) for $Name using command $Command$Name"

    $Socket = New-Socket
    try {
      Connect-Socket $Socket -RemoteIPAddress $WhoIsServer -RemotePort 43
    } catch [Net.Sockets.SocketException] {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object Net.Sockets.SocketException ($_.Exception.InnerException.NativeErrorCode)),
        "Connection to $IPAddress failed",
        [Management.Automation.ErrorCategory]::ConnectionError,
        $Socket)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
    
    Send-Bytes $Socket -Data ("$Command$Name`r`n" | ConvertTo-Byte)
    
    $ReceivedData = @()
    do {
      $ReceivedData += Receive-Bytes $Socket -BufferSize 4096
      Write-Verbose "Get-WhoIs: Received $($ReceivedData[-1].BytesReceived) bytes from $($ReceivedData[-1].RemoteEndPoint.Address)"
    } until ($ReceivedData[-1].BytesReceived -eq 0)

    $WhoIsRecord = ConvertTo-String ($ReceivedData | Select-Object -ExpandProperty Data)
    if ($WhoIsRecord -match 'ReferralServer: whois://(.+):') {
      Write-Verbose "Get-WhoIs: Following referral for $Name to $($matches[1])"
      Get-WhoIs $Name -WhoIsServer $matches[1]
    } else {
      $WhoIsRecord
    }
    Disconnect-Socket $Socket
    Remove-Socket $Socket
  }
}




function IsIpAddressInRange {
    param(
        [string] $ipAddress,
        [string] $fromAddress,
        [string] $toAddress
    )

    $ip = [system.net.ipaddress]::Parse($ipAddress).GetAddressBytes()
    [array]::Reverse($ip)
    $ip = [system.BitConverter]::ToUInt32($ip, 0)

    $from = [system.net.ipaddress]::Parse($fromAddress).GetAddressBytes()
    [array]::Reverse($from)
    $from = [system.BitConverter]::ToUInt32($from, 0)

    $to = [system.net.ipaddress]::Parse($toAddress).GetAddressBytes()
    [array]::Reverse($to)
    $to = [system.BitConverter]::ToUInt32($to, 0)

    $from -le $ip -and $ip -le $to
}

function Member-Query ( $entry, [String]$PaProp ) {
    if ($entry."$PaProp".member."#text") {
        return $entry."$PaProp".member."#text"
    } 
    else {
        return  $entry."$PaProp".member
    }
}

# This was pulled from within some other functions and isn't actually in use from what I can tell.
function Send-WebFile ($url) {
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($data)

    [System.Net.HttpWebRequest] $webRequest = [System.Net.WebRequest]::Create($url)

    $webRequest.Method = "POST"
    $webRequest.ContentType = "text/html"
    $webRequest.ContentLength = $buffer.Length;

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($buffer, 0, $buffer.Length)
    $requestStream.Flush()
    $requestStream.Close()


    [System.Net.HttpWebResponse] $webResponse = $webRequest.GetResponse()
    $streamReader = New-Object System.IO.StreamReader($webResponse.GetResponseStream())
    $result = $streamReader.ReadToEnd()
    return $result
}

function Text-Query ( $entry, [String]$PaProp ) {
    if ($entry."$PaProp"."#text") {
        return $entry."$PaProp"."#text"
    }
    else {
        return  $entry."$PaProp"
    }
}

## PUBLIC MODULE FUNCTIONS AND DATA ##

<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Connect-PA.md
    #>
function Connect-PA {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [ValidatePattern("\d+\.\d+\.\d+\.\d+|(\w\.)+\w")]
        [string]$Address,

        [Parameter(Mandatory=$True,Position=1)]
        [System.Management.Automation.PSCredential]$Cred,
        
        [Parameter(Position=2)]
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


Function Convert-OutputForCSV {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Convert-OutputForCSV.md
    #>
    #Requires -Version 3.0
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [psobject]$InputObject,
        [parameter()]
        [ValidateSet('Stack','Comma')]
        [string]$OutputPropertyType = 'Stack'
    )
    Begin {
        $PSBoundParameters.GetEnumerator() | ForEach {
            Write-Verbose "$($_)"
        }
        $FirstRun = $True
    }
    Process {
        If ($FirstRun) {
            $OutputOrder = $InputObject.psobject.properties.name
            Write-Verbose "Output Order:`n $($OutputOrder -join ', ' )"
            $FirstRun = $False
            #Get properties to process
            $Properties = Get-Member -InputObject $InputObject -MemberType *Property
            #Get properties that hold a collection
            $Properties_Collection = @(($Properties | Where-Object {
                $_.Definition -match "Collection|\[\]"
            }).Name)
            #Get properties that do not hold a collection
            $Properties_NoCollection = @(($Properties | Where-Object {
                $_.Definition -notmatch "Collection|\[\]"
            }).Name)
            Write-Verbose "Properties Found that have collections:`n $(($Properties_Collection) -join ', ')"
            Write-Verbose "Properties Found that have no collections:`n $(($Properties_NoCollection) -join ', ')"
        }
 
        $InputObject | ForEach {
            $Line = $_
            $stringBuilder = New-Object Text.StringBuilder
            $Null = $stringBuilder.AppendLine("[pscustomobject] @{")

            $OutputOrder | ForEach {
                If ($OutputPropertyType -eq 'Stack') {
                    $Null = $stringBuilder.AppendLine("`"$($_)`" = `"$(($line.$($_) | Out-String).Trim())`"")
                } ElseIf ($OutputPropertyType -eq "Comma") {
                    $Null = $stringBuilder.AppendLine("`"$($_)`" = `"$($line.$($_) -join ', ')`"")                   
                }
            }
            $Null = $stringBuilder.AppendLine("}")
 
            Invoke-Expression $stringBuilder.ToString()
        }
    }
    End {}
}


function Get-PAAddressGroup {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PAAddressGroup.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0)]
        [string]$Name,
        [Parameter(position=1)]
        [alias('pc')]
        [PSObject]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/address-group'
        
        if ( -not [string]::IsNullOrEmpty($Name) ) {
            $Xpath += '/entry[@name=%27' + $Name.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            $Groups = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutObjects = $Groups.response.result.'address-group'.entry
            }
            else {
                $OutObjects = $Groups.response.result.entry
            }
            if ($OutObjects -ne $null) {
                $OutObjects | ForEach-Object {
                    $OutProp = @{
                        'FirewallAddress' = $Connection.Address
                        'Name' = Text-Query $_ 'Name'
                    }
                    if ($_.static) {
                        $OutProp.MemberType = 'Static'
                        $OutProp.Members = Text-Query $_.static 'member'
                    }
                    else {
                        $OutProp.MemberType = 'Dynamic'
                        $OutProp.Members = Text-Query $_.dynamic 'filter'
                    }
                    
                    New-Object -TypeName PSObject -Property $OutProp
                }
            }
        }
    }
}


function Get-PaAddressObject {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PAAddressObject.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0)]
        [string]$Name,
        [Parameter(position=1)]
        [alias('pc')]
        [PSObject]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/address'
        
        if ( -not [string]::IsNullOrEmpty($Name) ) {
            $Xpath += '/entry[@name=%27' + $Name.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            $Addresses = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutObjects = $Addresses.response.result.address.entry
            }
            else {
                $OutObjects = $Addresses.response.result.entry
            }
            if ($OutObjects -ne $null) {
                $OutObjects | ForEach-Object {
                    New-Object -TypeName PSObject -Property @{
                        'FirewallAddress' = $Connection.Address
                        'Name' = Text-Query $_ 'Name'
                        'IP-Netmask' = Text-Query $_ 'ip-netmask'
                        'Description' = Text-Query $_ 'Description'
                        'tags' = Member-Query $_ 'tag'
                    }
                }
            }
        }
    }
}


function Get-PAConnectionList {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PAConnectionList.md
    #>
    [CmdletBinding()]
    Param ()

    return $script:PaConnectionArray
}


function Get-PaConnectionString {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PaConnectionString.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        #[ValidatePattern("\d+\.\d+\.\d+\.\d+|(\w\.)+\w")]
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
        $password = ($cred.getnetworkcredential()).password
        $headers = @{"X-Requested-With"="powershell"}
        $URL = 'https://{0}/api/?type=keygen&user={1}&password={2}' -f $Address,$user,$password
        Write-Verbose "$($FunctionName): URL = $URL"
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


function Get-PAEthernetInterface {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PAEthernetInterface.md
    #>

    Param (
        [Parameter(position=0)]
        [string]$Name,
        [Parameter(position=1)]
        [PSObject]$PaConnection,
        [Parameter(position=2)]
        [switch]$Aggregate
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        if (-not $Aggregate) {
            $xpath = '/config/devices/entry/network/interface/ethernet'
            $inttype = 'ethernet'
        }
        else {
            $xpath = '/config/devices/entry/network/interface/aggregate-ethernet'
            $inttype = 'aggregate-ethernet'
        }
        
        if ( -not [string]::IsNullOrEmpty($Name) ) {
            $Xpath += '/entry[@name=%27' + $Name.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $Interfaces = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutputInterfaces = $Interfaces.response.result.$inttype.entry
            }
            else {
                $OutputInterfaces = $Interfaces.response.result.entry
            }
            $OutputInterfaces | ForEach {
                $objprops = @{
                    'FirewallAddress' = $Connection.Address
                    'Name' =  $_.'Name'
                    'aggregate-group' = Text-Query $_ 'aggregate-group'
                    'link-duplex' = Text-Query $_ 'link-duplex'
                    'link-speed' = Text-Query $_ 'link-speed'
                    'link-state' = Text-Query $_ 'link-state'
                    'lacp-port-priority' = Text-Query $_.lacp 'port-priority'
                    'ip' = $null
                    'interface-management-profile' = Text-Query $_ 'interface-management-profile'
                    'ipv6' = $null
                    'tag' = Text-Query $_ 'tag'
                    'comment' =  Text-Query $_ 'comment'
                }
                $subinterfaces = $_.layer3.units.entry
                
                # First output the initial interface
                New-Object -TypeName PSObject -Property $objprops
                
                # If we have any subinterfaces output these as well
                # As usual I'm only grabbing a small subset of the common properties.
                if ($subinterfaces.Count -gt 0) {
                    ForEach ($int in $subinterfaces) {
                        $objprops.Name = Text-Query $int 'Name'
                        $objprops.'interface-management-profile' = Text-Query $int 'interface-management-profile'
                        $objprops.tag = Text-Query $int 'tag'
                        $objprops.comment =  Text-Query $int 'comment'
                        $objprops.ip = Text-Query $int.ip.entry name
                        
                        New-Object -TypeName PSObject -Property $objprops
                    }
                }
            }
        }
    }
}


function Get-PAHighAvailability {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PAHighAvailability.md
    #>

    Param (
        [Parameter(position=0)]
        [alias('pc')]
        [PSObject]$PaConnection
    )
    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            $result = (Send-PaApiQuery -PAConnection $Connection.ConnectionString  -op "<show><high-availability><all></all></high-availability></show>").response.result
            if  ($result.enabled -eq 'yes') {
                $ResultOutput = @{
                     'FirewallAddress' = $Connection.Address
                     'Enabled' = $true
                     'Mode' = Text-Query $result.group.mode
                 }
                $result.group."local-info" | get-member | Where {$_.MemberType -eq 'Property'} | foreach {
                    $ResultOutput.$($_.Name) = $result.group.'local-info'.$($_.Name)
                 }
                 $ResultOutput.'running-sync' = $result.group.'running-sync'
                 $ResultOutput.'running-sync-enabled' = $result.group.'running-sync-enabled'
                 $result.group."peer-info" | get-member | Where {$_.MemberType -eq 'Property'} | foreach {
                    $ResultOutput.$('peer-' + $_.Name) = $result.group.'peer-info'.$($_.Name)
                 }
                 
                 New-Object -TypeName PSObject -Property $ResultOutput
            }
            else {
                $ResultOutput = @{
                     'FirewallAddress' = $Connection.Address
                     'Enabled' = $false
                 }
                 New-Object -TypeName PSObject -Property $ResultOutput
            }
        }
    }
}


function Get-PALastResponse {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PALastResponse.md
    #>
    [CmdletBinding()]
    Param ()

    return $script:LastResponse
}


function Get-PALastURL {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PALastURL.md
    #>
    [CmdletBinding()]
    Param ()

    return $script:LastURL
}


function Get-PALogJob {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PaLogJob.md
    #>

    Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet("get","finish")]
        [String]$Action,

        [Parameter(Mandatory=$True)]
        [alias('j')]
        [String]$Job,

        [Parameter()]
        [alias('pc')]
        [String]$PaConnection
    )

    BEGIN {
        Add-Type -AssemblyName System.Web
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

        Function Process-Query ( [String]$PaConnectionString ) {
            $url = $PaConnectionString

            $url += "&type=log"
            $url += "&action=$Action"
            $Url += "&job-id=$job"

            $script:lasturl  = $url
            $script:response = [xml]$WebClient.DownloadString($url)
            if ($script:response.response.status -ne "success") {
                Throw $script:response.response.result.msg
            }

            return $script:response
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}


function Get-PaNatPolicy {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PANATPolicy.md
    #>

    Param (
        [Parameter(position=0)]
        [string]$Rule,
        [Parameter(position=1)]
        [alias('pc')]
        [String]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/rulebase/nat/rules'
        
        if ( -not [string]::IsNullOrEmpty($Rule) ) {
            $Xpath += '/entry[@name=%27' + $Rule.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
        
        $ReturnObjectOrder = @(
            'Order',
            'FirewallAddress',
            'Name',
            'Disabled',
            'Description',
            'Tags',
            'SourceZone',
            'DestinationZone',
            'DestinationInterface',
            'Service',
            'SourceAddress',
            'DestinationAddress',
            'SourceTransType',
            'SourceTransAddressType',
            'SourceTransInterface',
            'SourceTransAddress',
            'BiDirectional',
            'DestTransEnabled',
            'DestTransAddress',
            'DestTransPort'
        )
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $RuleCount = 0
            $NATRules = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Rule) ) {
                $OutputRules = $NATRules.response.result.rules.entry
            }
            else {
                $OutputRules = $NATRules.response.result.entry
            }
            $OutputRules | ForEach {
                $ReturnObject = New-Object -TypeName PSObject -Property @{
                    'Order' = if ( -not [string]::IsNullOrEmpty($Rule) ) { $null } else { $RuleCount }
                    'FirewallAddress' = $Connection.Address
                    'Name' = $_.Name
                    'Disabled' = if ((Text-Query $_ 'disabled') -eq 'yes') {$true} else {$false}
                    'Description' = $_.Description
                    'Tags' = Member-Query $_ 'tag'
                    'SourceZone' = Member-Query $_ 'from'
                    'DestinationZone' = Member-Query $_ 'to'
                    'DestinationInterface' = Text-Query $_ 'to-interface'
                    'Service' = Text-Query $_ 'service'
                    'SourceAddress' = Member-Query $_ 'source'
                    'DestinationAddress' = Member-Query $_ 'destination'
                    'SourceTransType' = $null
                    'SourceTransAddressType' = $null
                    'SourceTransInterface' = $null
                    'SourceTransAddress' = $null
                    'BiDirectional' = $null
                    'DestTransEnabled' = $null
                    'DestTransAddress' = $null
                    'DestTransPort' = $null
                }
                    
                if ($_."source-translation"."dynamic-ip-and-port") {
                    $ReturnObject.SourceTransType = "DynamicIpAndPort"
                    if ($_."source-translation"."dynamic-ip-and-port"."interface-address".interface."#text") {
                        $ReturnObject.SourceTransAddressType = "InterfaceAddress"
                        $ReturnObject.SourceTransInterface = Text-Query $_."source-translation"."dynamic-ip-and-port"."interface-address" 'interface'
                        $ReturnObject.SourceTransAddress = Text-Query "source-translation"."dynamic-ip-and-port"."interface-address" 'ip'
                    }
                    elseif ($_."source-translation"."dynamic-ip-and-port"."interface-address".interface) {
                        $ReturnObject.SourceTransAddressType = "InterfaceAddress"
                        $ReturnObject.SourceTransInterface = Text-Query $_."source-translation"."dynamic-ip-and-port"."interface-address" 'interface'
                    }
                    elseif ($_."source-translation"."dynamic-ip-and-port"."translated-address") {
                        $ReturnObject.SourceTransAddressType = "TranslatedAddress"
                        $ReturnObject.SourceTransInterface = Text-Query $_."source-translation"."dynamic-ip-and-port" 'translated-address'
                    }
                }
                elseif ($_."source-translation"."static-ip") {
                    $ReturnObject.SourceTransType = "StaticIp"
                    $ReturnObject.SourceTransAddress = Text-Query $_."source-translation"."static-ip" 'translated-address'
                    $ReturnObject.BiDirectional = Text-Query $_."source-translation"."static-ip" 'bi-directional'
                }
                elseif ($_."source-translation"."dynamic-ip") {
                    $ReturnObject.SourceTransType = "DynamicIp"
                    $ReturnObject.SourceTransAddress = Text-Query $_."source-translation"."dynamic-ip"."translated-address" 'member'
                }
                if ($_."destination-translation") {
                    $ReturnObject.DestTransEnabled = "yes"
                    $ReturnObject.DestTransAddress = Text-Query $_."destination-translation" 'translated-address'
                    $ReturnObject.DestTransPort = Text-Query $_."destination-translation" 'translated-port'
                }

                $RuleCount++
                $ReturnObject | Select $ReturnObjectOrder
            }
        }
    }
}


function Get-PaSecurityPolicy {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PaSecurityPolicy.md
    #>

    Param (
        [Parameter(position=0)]
        [string]$Rule,
        [Parameter(position=1)]
        [alias('pc')]
        [String]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1',
        [Parameter(position=3)]
        [switch]$Candidate
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        if ($Candidate) {
            $type = "get"
        }
        else {
            $type = "show"
        }

        $xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/rulebase/security/rules'
        
        if ( -not [string]::IsNullOrEmpty($Rule) ) {
            $Xpath += '/entry[@name=%27' + $Rule.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
        
        $ReturnObjectOrder = @(
            'Order',
            'FirewallAddress',
            'Name',
            'Disabled',
            'Description',
            'Tags',
            'SourceZone',
            'SourceAddress',
            'SourceNegate',
            'SourceUser',
            'HipProfile',
            'DestinationZone',
            'DestinationAddress',
            'DestinationNegate',
            'Application',
            'Service',
            'UrlCategory',
            'Action',
            'ProfileType',
            'ProfileGroup',
            'ProfileVirus',
            'ProfileVuln',
            'ProfileSpy',
            'ProfileUrl',
            'ProfileFile',
            'ProfileData',
            'LogStart',
            'LogEnd',
            'LogForward',
            'DisableSRI',
            'Schedule',
            'QosType',
            'QosMarking'
        )
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $RuleCount = 0
            $SecurityRules = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config $type -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Rule) ) {
                $OutputRules = $SecurityRules.response.result.rules.entry
            }
            else {
                $OutputRules = $SecurityRules.response.result.entry
            }
            $OutputRules | ForEach {
                $ReturnObject = New-Object -TypeName PSObject -Property @{
                    'Order' = if ( -not [string]::IsNullOrEmpty($Rule) ) { $null } else { $RuleCount }
                    'FirewallAddress' = $Connection.Address
                    'Name' = $_.Name
                    'Disabled' = if ((Text-Query $_ 'disabled') -eq 'yes') {$true} else {$false}
                    'Description' = $_.Description
                    'Tags' = Member-Query $_ 'tag'
                    'SourceZone' = Member-Query $_ 'from'
                    'SourceAddress' = Member-Query $_ 'source'
                    'SourceNegate' = Text-Query $_ 'negate-source'
                    'SourceUser' = Member-Query $_ 'source-user'
                    'HipProfile' = Member-Query $_ 'hip-profiles'
                    'DestinationZone' = Member-Query $_ 'to'
                    'DestinationAddress' =  Member-Query $_ 'destination'
                    'DestinationNegate' = Text-Query $_ 'negate-destination'
                    'Application' = Member-Query $_ 'application'
                    'Service' = Member-Query $_ 'service'
                    'UrlCategory' = Member-Query $_ 'category'
                    'Action' = Text-Query $_ 'action'
                    'ProfileType' = $null
                    'ProfileGroup' = $null
                    'ProfileVirus' = $null
                    'ProfileVuln' = $null
                    'ProfileSpy' = $null
                    'ProfileUrl' = $null
                    'ProfileFile' = $null
                    'ProfileData' = $null
                    'LogStart' = Text-Query $_ 'log-start'
                    'LogEnd' = Text-Query $_ 'log-end'
                    'LogForward' = Text-Query $_ 'log-setting'
                    'DisableSRI' = Text-Query $_.option 'disable-server-response-inspection'
                    'Schedule' = Text-Query $_ 'schedule'
                    'QosType' = $null
                    'QosMarking' = $null
                }

                if ($_.'profile-setting'.group) {
                    $ReturnObject.ProfileGroup   = Member-Query $_.'profile-setting' 'group'
                    $ReturnObject.ProfileType    = 'group'
                }
                elseif ($_.'profile-setting'.profiles) {
                    $ReturnObject.ProfileType    = 'profiles'
                    $ReturnObject.ProfileVirus   = Member-Query $_.'profile-setting'.profiles 'virus'
                    $ReturnObject.ProfileVuln    = Member-Query $_.'profile-setting'.profiles 'vulnerability'
                    $ReturnObject.ProfileSpy     = Member-Query $_.'profile-setting'.profiles 'spyware'
                    $ReturnObject.ProfileUrl     = Member-Query $_.'profile-setting'.profiles 'url-filtering'
                    $ReturnObject.ProfileFile    = Member-Query $_.'profile-setting'.profiles 'file-blocking'
                    $ReturnObject.ProfileData    = Member-Query $_.'profile-setting'.profiles 'data-filtering'
                }

                if ($_.qos.marking.'ip-dscp') {
                    $ReturnObject.QosType        = 'ip-dscp'
                    $ReturnObject.QosMarking     = Text-Query $_.qos.marking 'ip-dscp'
                }
                elseif ($_.qos.marking.'ip-precedence') {
                    $ReturnObject.QosType        = 'ip-precedence'
                    $ReturnObject.QosMarking     = Text-Query $_.qos.marking 'ip-precedence'
                }

                $RuleCount++
                $ReturnObject | Select $ReturnObjectOrder
            }
        }
    }
}


function Get-PaSystemInfo {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PASystemInfo.md
    #>

    Param (
        [Parameter(position=0)]
        [alias('pc')]
        [PSObject]$PaConnection
    )
    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            (Send-PaApiQuery -PAConnection $Connection.ConnectionString  -op "<show><system><info></info></system></show>").response.result.system
        }
    }
}


function Get-PAZone {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Get-PAZone.md
    #>

    Param (
        [Parameter(position=0)]
        [string]$Name,
        [Parameter(position=1)]
        [alias('pc')]
        [String]$PaConnection,
        [Parameter(position=2)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $xpath = '/config/devices/entry/vsys/entry[@name=%27' + $Target + '%27]/zone'
        
        if ( -not [string]::IsNullOrEmpty($Name) ) {
            $Xpath += '/entry[@name=%27' + $Name.replace(" ",'%20') + '%27]'
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }
    
    Process {
        foreach ($Connection in $PaConnections) {
            $Zones = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'get' -XPath $Xpath
            if ( [string]::IsNullOrEmpty($Name) ) {
                $OutputZones = $Zones.response.result.zone.entry
            }
            else {
                $OutputZones = $Zones.response.result.entry
            }
            $OutputZones | ForEach {
                if ($_.network.'virtual-wire'.member) {
                    $network = $_.network.'virtual-wire'.member
                }
                elseif ($_.network.layer3.member) {
                    $network = $_.network.layer3.member
                }
                else {
                    $network = $null
                }

                 New-Object -TypeName PSObject -Property @{
                    'FirewallAddress' = $Connection.Address
                    'Name' =  $_.'Name'
                    'Network' = $network
                }
            }
        }
    }
}


function Invoke-PACommit {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Invoke-PaCommit.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [PSObject]$PaConnection,

        [Parameter()]
        [switch]$Force
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand

        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
        
            if ($Force) {
                $CustomData = Send-PaApiQuery -PAConnection $Connection.ConnectionString -commit -force
            }
            else {
                $CustomData = Send-PaApiQuery -PAConnection $Connection.ConnectionString -commit
            }
            if ($CustomData.response.status -eq "success") {
                if ($CustomData.response.msg -match "no changes") {
                    Write-Warning "$($FunctionName): There are no changes to commit."
                }
                $job = $CustomData.response.result.job
                $cmd = "<show><jobs><id>$job</id></jobs></show>"
                $JobStatus = Send-PaApiQuery -PAConnection $Connection.ConnectionString -op "$cmd"
                while ($JobStatus.response.result.job.status -ne "FIN") {
                    Write-Progress -Activity "Commiting to PA" -Status "$($JobStatus.response.result.job.progress)% complete"-PercentComplete ($JobStatus.response.result.job.progress)
                    $JobStatus = Send-PaApiQuery -op "$cmd"
                    sleep -Seconds 1
                }
                Write-Output $JobStatus.response.result.job
                return
            }
            throw "$($CustomData.response.result.msg)"
        }
    }
}


function New-PaAddressObject {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/New-PaAddressObject.md
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


function New-PaLogJob {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/New-PaLogJob.md
    #>

    Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet("traffic","threat","config","system","hip-match")]
        [String]$Type,

        [Parameter(Mandatory=$True)]
        [String]$Query,

        [Parameter()]
        [ValidateRange(1,5000)]
        [Decimal]$NumberLogs,

        [Parameter()]
        [String]$Skip,

        [Parameter()]
        [String]$PaConnection
    )

    BEGIN {
        Add-Type -AssemblyName System.Web
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

        Function Process-Query ( [String]$PaConnectionString ) {
            $url = $PaConnectionString

            $url += "&type=log"
            $url += "&log-type=$Type"

            if ($Query)      { $Query  = [System.Web.HttpUtility]::UrlEncode($Query)
                               $url   += "&query=$Query" }
            if ($NumberLogs) { $url += "&nlogs=$NumberLogs" }
            if ($Skip)       { $url += "&skip=$SkipLogs" }

            $script:lasturl  = $url
            $script:response = [xml]$WebClient.DownloadString($url)
            if ($script:response.response.status -ne "success") {
                Throw $script:response.response.result.msg
            }

            return $script:response
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}


function Rename-PaAddressObject {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Rename-PAAddressObject.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [string]$Name,
        [Parameter(position=1, Mandatory=$True)]
        [ValidateLength(1,32)]
        [string]$NewName,
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter()]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/address/entry[@name='" + $Name.replace(" ",'%20') + "']" #&newname=" + $NewName.replace(" ",'%20')
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            try {
                $null = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'rename' -XPath $Xpath -NewName $NewName.replace(" ",'%20')
            }
            catch {
                Write-Error "$($FunctionName): There was an issue renaming $($Name) to $($NewName) on $($Connection.Address)..."
            }
        }
    }
}


function Rename-PANATPolicy {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Rename-PANATPolicy.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [string]$Name,
        [Parameter(position=1, Mandatory=$True)]
        [ValidateLength(1,32)]
        [string]$NewName,
        [Parameter(position=2)]
        [PSObject]$PaConnection,
        [Parameter(position=3)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/rulebase/nat/rules/entry[@name='" + $Name.replace(" ",'%20') + "']"
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            try {
                $null = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'rename' -XPath $Xpath -NewName $NewName.replace(" ",'%20')
            }
            catch {
                Write-Warning "$($FunctionName): There was an issue renaming $($Name) to $($NewName) on $($Connection.Address)..."
            }
        }
    }
}


function Rename-PaSecurityPolicy {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Rename-PASecurityPolicy.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [string]$Name,
        [Parameter(position=1, Mandatory=$True)]
        [ValidateLength(1,32)]
        [string]$NewName,
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter()]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/rulebase/security/rules/entry[@name='" + $Name.replace(" ",'%20') + "']"
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            try {
                $null = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'rename' -XPath $Xpath -NewName $NewName.replace(" ",'%20')
            }
            catch {
                Write-Error "$($FunctionName): There was an issue renaming $($Name) to $($NewName) on $($Connection.Address)..."
            }
        }
    }
}


function Send-PaApiQuery {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Send-PaApiQuery.md
    #>
    Param (
        #############################CONFIG#############################

        [Parameter(ParameterSetName="config",Mandatory=$True,Position=0)]
        [ValidateSet("show","get","set","edit","delete","rename","clone","move")]
        [String]$Config,

        [Parameter(ParameterSetName="config",Mandatory=$True)]
        [ValidatePattern("\/config\/.*")]
        [String]$XPath,

        [Parameter(ParameterSetName="config")]
        [alias('e')]
        [String]$Element,

        [Parameter(ParameterSetName="config")]
        [alias('m')]
        [String]$Member,

        [Parameter(ParameterSetName="config")]
        [alias('nn')]
        [String]$NewName,

            #========================CLONE=========================#

        [Parameter(ParameterSetName="config")]
        [alias('cf')]
        [String]$CloneFrom,

            #=========================MOVE=========================#

        [Parameter(ParameterSetName="config")]
        [alias('mw')]
        [ValidateSet("after","before","top","bottom")] 
        [String]$MoveWhere,

        [Parameter(ParameterSetName="config")]
        [alias('dst')]
        [String]$MoveDestination,

        ###########################OPERATIONAL##########################

        [Parameter(ParameterSetName="op",Mandatory=$True,Position=0)]
        [ValidatePattern("<\w+>.*<\/\w+>")]
        [String]$Op,

        #############################REPORT#############################

        [Parameter(ParameterSetName="report",Mandatory=$True,Position=0)]
        [ValidateSet("dynamic","predefined")]
        #No Custom Reports supported yet, should probably make a seperate cmdlet for it.
        [String]$Report,

        [Parameter(ParameterSetName="report")]
        [alias('rn')]
        [String]$ReportName,

        [Parameter(ParameterSetName="report")]
        [alias('r')]
        [Decimal]$Rows,

        [Parameter(ParameterSetName="report")]
        [alias('p')]
        [ValidateSet("last-60-seconds","last-15-minutes","last-hour","last-12-hrs","last-24-hrs","last-calendar-day","last-7-days","last-7-calendar-days","last-calendar-week","last-30-days")] 
        [String]$Period,

        [Parameter(ParameterSetName="report")]
        [alias('start')]
        [ValidatePattern("\d{4}\/\d{2}\/\d{2}\+\d{2}:\d{2}:\d{2}")]
        [String]$StartTime,

        [Parameter(ParameterSetName="report")]
        [alias('end')]
        [ValidatePattern("\d{4}\/\d{2}\/\d{2}\+\d{2}:\d{2}:\d{2}")]
        [String]$EndTime,

        #############################EXPORT#############################

        [Parameter(ParameterSetName="export",Mandatory=$True,Position=0)]
        [ValidateSet("application-pcap","threat-pcap","filter-pcap","filters-pcap","configuration","certificate","high-availability-key","key-pair","application-block-page","captive-portal-text","file-block-continue-page","file-block-page","global-protect-portal-custom-help-page","global-protect-portal-custom-login-page","global-protect-portal-custom-welcome-page","ssl-cert-status-page","ssl-optout-text","url-block-page","url-coach-text","virus-block-page","tech-support","device-state")]
        [String]$Export,

        [Parameter(ParameterSetName="export")]
        [alias('f')]
        [String]$From,

        [Parameter(ParameterSetName="export")]
        [alias('t')]
        [String]$To,

            #=========================DLP=========================#

        [Parameter(ParameterSetName="export")]
        [alias('dp')]
        [String]$DlpPassword,

            #=====================CERTIFICATE=====================#

        [Parameter(ParameterSetName="export")]
        [alias('ecn')]
        [String]$CertificateName,

        [Parameter(ParameterSetName="export")]
        [alias('ecf')]
        [ValidateSet("pkcs12","pem")]
        [String]$CertificateFormat,

        [Parameter(ParameterSetName="export")]
        [alias('epp')]
        [String]$ExportPassPhrase,

            #=====================TECH SUPPORT====================#

        [Parameter(ParameterSetName="export")]
        [alias('ta')]
        [ValidateSet("status","get","finish")]
        [String]$TsAction,

        [Parameter(ParameterSetName="export")]
        [alias('j')]
        [Decimal]$Job,

        [Parameter(ParameterSetName="export",Mandatory=$True)]
        [alias('ef')]
        [String]$ExportFile,


        #############################IMPORT#############################

        [Parameter(ParameterSetName="import",Mandatory=$True,Position=0)]
        [ValidateSet("software","anti-virus","content","url-database","signed-url-database","license","configuration","certificate","high-availability-key","key-pair","application-block-page","captive-portal-text","file-block-continue-page","file-block-page","global-protect-portal-custom-help-page","global-protect-portal-custom-login-page","global-protect-portal-custom-welcome-page","ssl-cert-status-page","ssl-optout-text","url-block-page","url-coach-text","virus-block-page","global-protect-client","custom-logo")]
        [String]$Import,

        [Parameter(ParameterSetName="import",Mandatory=$True,Position=1)]
        [String]$ImportFile,

            #=====================CERTIFICATE=====================#

        [Parameter(ParameterSetName="import")]
        [alias('icn')]
        [String]$ImportCertificateName,

        [Parameter(ParameterSetName="import")]
        [alias('icf')]
        [ValidateSet("pkcs12","pem")]
        [String]$ImportCertificateFormat,

        [Parameter(ParameterSetName="import")]
        [alias('ipp')]
        [String]$ImportPassPhrase,

            #====================RESPONSE PAGES====================#

        [Parameter(ParameterSetName="import")]
        [alias('ip')]
        [String]$ImportProfile,

            #=====================CUSTOM LOGO======================#

        [Parameter(ParameterSetName="import")]
        [alias('wh')]
        [ValidateSet("login-screen","main-ui","pdf-report-footer","pdf-report-header")]
        [String]$ImportWhere,

        ##############################LOGS##############################

        [Parameter(ParameterSetName="log",Mandatory=$True,Position=0)]
        [ValidateSet("traffic","threat","config","system","hip-match","get","finish")]
        [String]$Log,

        [Parameter(ParameterSetName="log")]
        [alias('q')]
        [String]$LogQuery,

        [Parameter(ParameterSetName="log")]
        [alias('nl')]
        [ValidateRange(1,5000)]
        [Decimal]$NumberLogs,

        [Parameter(ParameterSetName="log")]
        [alias('sl')]
        [String]$SkipLogs,

        [Parameter(ParameterSetName="log")]
        [alias('la')]
        [ValidateSet("get","finish")]
        [String]$LogAction,

        [Parameter(ParameterSetName="log")]
        [alias('lj')]
        [Decimal]$LogJob,

        #############################USER-ID############################

        [Parameter(ParameterSetName="userid",Mandatory=$True,Position=0)]
        [ValidateSet("get","set")] 
        [String]$UserId,

        #############################COMMIT#############################

        [Parameter(ParameterSetName="commit",Mandatory=$True,Position=0)]
        [Switch]$Commit,

        [Parameter(ParameterSetName="commit")]
        [Switch]$Force,

        [Parameter(ParameterSetName="commit")]
        [alias('part')]
        [String]$Partial,

        ############################CONNECTION##########################

        [Parameter()]
        [alias('pc')]
        [String]$PaConnection
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using existing connections to $(($script:PaConnectionArray).Count) Firewalls."
                $PaConnections = @($script:PaConnectionArray)
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            Write-Verbose "$($FunctionName): Processing against connection to $($Connection.Address)"
            $url = $Connection.ConnectionString
            switch ($PSCmdlet.ParameterSetName) {
                'Config' {
                    $ReturnType = "String"
                    $url += "&type=config"
                    $url += "&action=$Config"
                    $url += "&xpath=$xpath"
                    if (($Config -eq "set") -or ($Config -eq "edit")-or ($Config -eq "delete")) {
                        #if ($Element) { $url += "/$Element" }
                        $Members = ''
                        if ($Member) {
                            $Member = $Member.replace(" ",'%20')
#                        if ($Member -match ",") {
                        
                            foreach ($Value in $Member.split(',')) {
                                if ($Value) { $Members += "<member>$Value</member>" }
                            }
                            $Member = $Members
                        }
                        if ($Element) {
                            $url += "&element=<$element>$Member</$element>"
                        }
                        elseif ($Member -ne '') {
                            $url += "&element=$Member"
                        }
                    } elseif ($Config -eq "rename") {
                        $url += "&newname=$NewName"
                    } elseif ($Config -eq "clone") {
                        $url += "/"
                        $url += "&from=$xpath/$CloneFrom"
                        $url += "&newname=$NewName"
                        return "Times out ungracefully as of 11/20/12 on 5.0.0"
                    } elseif ($Config -eq "move") {
                        $url += "&where=$MoveWhere"
                        if ($MoveDestination) {
                            $url += "&dst=$MoveDestination"
                        }
                    }

                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
                'Op' {
                    $ReturnType = "String"
                    $url += "&type=op"
                    $url += "&cmd=$Op"

                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
                'Report' {
                    $ReturnType = "String"
                    $url += "&type=report"
                    $url += "&reporttype=$Report"
                    if ($ReportName) { $url += "&reportname=$ReportName" }
                    if ($Rows) { $url += "&topn=$Rows" }
                    if ($Period) {
                        $url+= "&period=$Period"
                    } elseif ($StartTime) {
                        $url += "&starttime=$StartTime"
                        if ($EndTime) { $url += "&starttime=$EndTime" }
                    }
                    Get-WebRequestAsXML $url
                }
                'Export' {
                    if (($export -eq "filters-pcap") -or ($export -eq "filter-pcap")) {
                        return "Times out ungracefully as of 11/20/12 on 5.0.0"
                    }
                    $url += "&type=export"
                    $url += "&category=$Export"
                    if ($From) { $url += "&from=$From" }
                    if ($To) { $url += "&to=$To" }
                    if ($DlpPassword) { $url += "dlp-password=$DlpPassword" }
                    if ($CertificateName) {
                        $url += "&certificate-name=$CertificateName"
                        $url += "&include-key=no"
                    }
                    if ($CertificateFormat) { $url += "&format=$CertificateFormat" }
                    if ($ExportPassPhrase) {
                        $url += "&include-key=yes"
                        $url += "&passphrase=$ExportPassPhrase"
                    }
                    if ($TsAction) { $url += "&action=$TsAction" }
                    if ($Job) { $url += "&job-id=$Job" }
                    try {
                        Get-WebRequestAsXML $url $ExportFile
                        Write-Output "$($FunctionName): File downloaded to $ExportFile"
                    }
                    catch {
                        throw 'Unable to export file!'
                    }
                }
                'Import' {
                    $url += "&type=import"
                    $url += "&category=$Import"
                    if ($ImportCertificateName) {
                        $url += "&certificate-name=$ImportCertificateName"
                        $url += "&format=$ImportCertificateFormat"
                        $url += "&passphrase=$ImportPassPhrase"
                    }
                    if ($ImportProfile) { $url += "&profile=$ImportProfile" }
                    if ($ImportWhere) { $url += "&where=$ImportWhere" }
                    $script:LastURL = $url

                    #return Send-WebFile $url $ImportFile
                    return "Currently non-functional, not sure how to do this with webclient"
                }
                'Log' {
                    $url += "&type=log"
                    if ($Log -eq "get") {
                        $url += "&action=$log"
                        $url += "&job-id=$LogJob"
                    } else {
                        $url += "&log-type=$Log"
                    }

                    
                    if ($LogQuery) {
                        $Query  = [System.Web.HttpUtility]::UrlEncode($LogQuery)
                        $url   += "&query=$Query"
                    }
                    if ($NumberLogs) { $url += "&nlogs=$NumberLogs" }
                    if ($SkipLogs) { $url += "&skip=$SkipLogs" }

                    $script:LastURL  = $url
                    $script:LastResponse = Get-WebRequestAsXML $url

                    $script:LastResponse
                }
                'UserID' {
                    $url += "&type=user-id"
                    $url += "&action=$UserId"
                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
                'Commit' {
                    $url += "&type=commit"
                    $url += "&cmd=<commit></commit>"
                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
            }
        }
    }
}


function Set-PaAddressObject {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Set-PaAddressObject.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True)]
        [string]$Name,
        [Parameter(position=1)]
        [string]$IPNetmask,
        [Parameter(position=2)]
        [string]$Description,
        [Parameter(position=3)]
        [PSObject]$PaConnection,
        [Parameter(position=4)]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand

        if ((-not $Description) -and (-not $IPNetmask) -and ($Tags.Count -eq 0)) {
            throw "$($FunctionName): Object requires a property to set!"
        }
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/address/entry[@name='" + $Name.replace(" ",'%20') + "']&element="
        if ( $IPNetmask ) {
            $Xpath += "<ip-netmask>$IPNetmask</ip-netmask>"
        }
        if ( $Description ) {
            $Xpath += "<description>" + $Description.replace(" ",'%20') + "</description>"
        }
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            try {
                $Addresses = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'set' -XPath $Xpath
            }
            catch {
                Write-Error "$($FunctionName): There was an issue creating this object against $($Connection.Address)..."
            }
        }
    }
}


function Set-PaAddressObjectTag {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Set-PaAddressObjectTag.md
    #>
    [CmdletBinding()]
    Param (
        [Parameter(position=0, Mandatory=$True,ValueFromPipeline=$True)]
        [string]$Name,
        [Parameter(position=1, Mandatory=$True)]
        [string]$Tags,
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter()]
        [ValidateSet('vsys1','panorama')]
        [string]$Target = 'vsys1'
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand
        
        $Xpath = "/config/devices/entry/vsys/entry[@name='$Target']/address/entry[@name='" + $Name.replace(" ",'%20') + "']/tag"
        
        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using module connection string."
                $PaConnections = $script:PaConnectionArray
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            try {
                $Addresses = Send-PaApiQuery -PAConnection $Connection.ConnectionString -Config 'set' -XPath $Xpath -Member $Tags
            }
            catch {
                Write-Error "$($FunctionName): There was an issue creating this object against $($Connection.Address)..."
            }
        }
    }
}


function Set-PaSecurityRule {
	<#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Set-PaSecurityRule.md
    #>
    
    Param (
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$Rename,
        [Parameter()]
        [string]$Description,
        [Parameter()]
        [string]$Tag,
        [Parameter()]
        [string]$SourceZone,
        [Parameter()]
        [string]$SourceAddress,
        [Parameter()]
        [string]$SourceUser,
        [Parameter()]
        [string]$HipProfile,
        [Parameter()]
        [string]$DestinationZone,
        [Parameter()]
        [string]$DestinationAddress,
        [Parameter()]
        [string]$Application,
        [Parameter()]
        [string]$Service,
        [Parameter()]
        [string]$UrlCategory,
        [Parameter()]
        [ValidateSet("yes","no")]
        [string]$SourceNegate,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$DestinationNegate,
        [Parameter()]
        [ValidateSet("allow","deny")] 
        [string]$Action,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$LogStart,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$LogEnd,
        [Parameter()]
        [string]$LogForward,
        [Parameter()]
        [string]$Schedule,
        [Parameter()]
        [ValidateSet("yes","no")]
        [string]$Disabled,
        [Parameter()]
        [string]$ProfileGroup,
        [Parameter()]
        [string]$ProfileVirus,
        [Parameter()]
        [string]$ProfileVuln,
        [Parameter()]
        [string]$ProfileSpy,
        [Parameter()]
        [string]$ProfileUrl,
        [Parameter()]
        [string]$ProfileFile,
        [Parameter()]
        [string]$ProfileData,
        [Parameter()]
        [ValidateSet("none","af11","af12","af13","af21","af22","af23","af31","af32","af33","af41","af42","af43","cs0","cs1","cs2","cs3","cs4","cs5","cs6","cs7","ef")] 
        [string]$QosDscp,
        [Parameter()]
        [ValidateSet("none","cs0","cs1","cs2","cs3","cs4","cs5","cs6","cs7")] 
        [string]$QosPrecedence,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$DisableSri
    )

    BEGIN {
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

        function EditProperty ($parameter,$element,$xpath) {
            if ($parameter) {
                if ($parameter -eq "none") { $action = "delete" } `
                    else                   { $action = "edit" }
                $Response = Send-PaApiQuery -Config $action -XPath $xpath -Element $element -Member $parameter
                if ($Response.response.status -eq "success") {
                    return "$element`: success"
                } else {
                    throw $Response.response.msg.line
                }
            }
        }
        Function Process-Query ( [String]$PaConnectionString ) {
            $xpath = "/config/devices/entry/vsys/entry/rulebase/security/rules/entry[@name='$Name']"
            
            if ($Rename) {
                $Response = Send-PaApiQuery -Config rename -XPath $xpath -NewName $Rename -PaConnection $PaConnectionString
                if ($Response.response.status -eq "success") {
                    return "Rename success"
                } else {
                    throw $Response.response.msg.line
                }
            }

            EditProperty $Description "description" $xpath
            EditProperty $SourceNegate "negate-source" $xpath
            EditProperty $DestinationNegate "negate-destination" $xpath
            EditProperty $Action "action" $xpath
            EditProperty $LogStart "log-start" $xpath
            EditProperty $LogEnd "log-end" $xpath
            EditProperty $LogForward "log-setting" $xpath
            EditProperty $Schedule "schedule" $xpath
            EditProperty $Disabled "disabled" $xpath
            EditProperty $QosDscp "ip-dscp" "$xpath/qos/marking"
            EditProperty $QosPrecedence "ip-precedence" "$xpath/qos/marking"
            EditProperty $DisableSri "disable-server-response-inspection" "$xpath/option"
            EditProperty $SourceAddress "source" $xpath
            EditProperty $SourceZone "from" $xpath
            EditProperty $Tag "tag" $xpath
            EditProperty $SourceUser "source-user" $xpath
            EditProperty $HipProfile "hip-profiles" $xpath
            EditProperty $DestinationZone "to" $xpath
            EditProperty $DestinationAddress "destination" $xpath
            EditProperty $Application "application" $xpath
            EditProperty $Service "service" $xpath
            EditProperty $UrlCategory "category" $xpath
            EditProperty $HipProfile "hip-profiles" $xpath
            EditProperty $ProfileGroup "group" "$xpath/profile-setting"
            EditProperty $ProfileVirus "virus" "$xpath/profile-setting/profiles"
            EditProperty $ProfileVuln "vulnerability" "$xpath/profile-setting/profiles"
            EditProperty $ProfileSpy "spyware" "$xpath/profile-setting/profiles"
            EditProperty $ProfileUrl "url-filtering" "$xpath/profile-setting/profiles"
            EditProperty $ProfileFile "file-blocking" "$xpath/profile-setting/profiles"
            EditProperty $ProfileData "data-filtering" "$xpath/profile-setting/profiles"
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $Script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
        
    }
}


function Test-PaConnection {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Test-PaConnection.md
    #>
    if ( -not ($Script:PaConnectionArray) ) {
        return $false
    } 
    else {
        return $true
    }
}


function Update-PaContent {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Update-PaContent.md
    #>

    Param (
        [Parameter(Mandatory=$False)]
        [alias('pc')]
        [String]$PaConnection
    )

    BEGIN {
        Function Process-Query ( [String]$PaConnectionString ) {
            $UpToDate = $false

            $xpath = "<request><content><upgrade><check></check></upgrade></content></request>"
            Write-Verbose "checking for new content"
            $ContentUpdate = Send-PaApiQuery -Op $xpath
            if ($ContentUpdate.response.status -ne "success") { throw $ContentUpdate.response.msg }
            if ($ContentUpdate.response.result."content-updates".entry.current -eq "no") {            
                if ($ContentUpdate.response.result."content-updates".entry.downloaded -eq "no") {
                    $xpath = "<request><content><upgrade><download><latest></latest></download></upgrade></content></request>"
                    $ContentDownload = Send-PaApiQuery -Op $xpath
                    if ($ContentDownload.response.status -ne "success") { throw $ContentDownload.response.msg }
                    
                    $job = $ContentDownload.response.result.job
                    $size = [Decimal]($ContentUpdate.response.result."content-updates".entry.size)
                    $Version = $ContentUpdate.response.result."content-updates".entry.version
                    $Status = Watch-PaJob -Job $job -c "Downloading $Version" -s $Size
                    if ($Status.response.status -ne "success") { throw $Status.response.msg }
                }
                else {
                    Write-Verbose "content already downloaded"
                }
                $xpath = "<request><content><upgrade><install><version>latest</version></install></upgrade></content></request>"
                $ContentInstall = Send-PaApiQuery -Op $xpath
                $Job = $ContentInstall.response.result.job
                $Status = Watch-PaJob -Job $job -c "Installing content $Version"
                
                if ($Status.response.result.job.details.Line.newjob.nextjob) {
                    $Job = $Status.response.result.job.details.Line.newjob.nextjob
                    $Status = Watch-PaJob -Job $job -c "New content push"
                }
            } 
            else {
                $UpToDate = $true
                Write-Verbose "content already installed"
            }

            $xpath = "<request><anti-virus><upgrade><check></check></upgrade></anti-virus></request>"
            "checking for new antivirus"
            $AvUpdate = Send-PaApiQuery -Op $xpath
            if ($AvUpdate.response.status -ne "success") { throw $AvUpdate.response.msg }

            if ($AvUpdate.response.result."content-updates".entry.current -eq "no") {
                if ($AvUpdate.response.result."content-updates".entry.downloaded -eq "no") {
                    $xpath = "<request><anti-virus><upgrade><download><latest></latest></download></upgrade></anti-virus></request>"
                    $AvDownload = Send-PaApiQuery -Op $xpath
                    if ($AvDownload.response.status -ne "success") { throw $AvDownload.response.msg }
                    
                    $job = $AvDownload.response.result.job
                    $size = [Decimal]($AvUpdate.response.result."content-updates".entry.size)
                    $Version = $AvUpdate.response.result."content-updates".entry.version
                    $Status = Watch-PaJob -Job $job -c "Downloading antivirus $Version" -s $Size
                    if ($Status.response.status -ne "success") { throw $Status.response.msg }
                }
                else {
                    Write-Verbose "antivirus already downloaded"
                }
                $xpath = "<request><anti-virus><upgrade><install><version>latest</version></install></upgrade></anti-virus></request>"
                $AvInstall = Send-PaApiQuery -Op $xpath
                if ($AvInstall.response.status -ne "success") { throw $AvInstall.response.msg }
                
                $job = $AvInstall.response.result.job
                $Status = Watch-PaJob -Job $Job -c "Installing antivirus $Version"
                if ($Status.response.status -ne "success") { throw $Status.response.msg }
                
                if ($status.response.result.job.details.line.newjob.nextjob) {
                    $Job = $status.response.result.job.details.line.newjob.nextjob
                    $Status = Watch-PaJob -Job $job -c "pushing antivirus"
                }
            } else {
                $UpToDate = $true
                "antivirus already install"
            }

            return $UpToDate
        }
    }
    
    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}


function Update-PaSoftware {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Update-PaSoftware.md
    #>

    Param (
        [Parameter()]
        [String]$PaConnection,

        [Parameter(Mandatory=$True)]
        [ValidatePattern("\d\.\d\.\d(-\w\d+)?|latest")]
        [String]$Version,

        [Parameter()]
        [Switch]$DownloadOnly,

        [Parameter()]
        [Switch]$NoRestart
    )

    BEGIN {
        Function Get-Stepping ( [String]$Version ) {
            $Stepping = @()
            $UpdateCheck = Send-PaApiQuery -Op "<request><system><software><check></check></software></system></request>"
            if ($UpdateCheck.response.status -eq "success") {
                $VersionInfo = Send-PaApiQuery -Op "<request><system><software><info></info></software></system></request>"
                $AllVersions = $VersionInfo.response.result."sw-updates".versions.entry
                $DesiredVersion = $AllVersions | where { $_.version -eq "$Version" }
                if (!($DesiredVersion)) { return "version $Version not listed" }
                $DesiredBase = $DesiredVersion.version.Substring(0,3)
                $CurrentVersion = (Get-PaSystemInfo)."sw-version"
                $CurrentBase = $CurrentVersion.Substring(0,3)
                if ($CurrentBase -eq $DesiredBase) {
                    $Stepping += $Version
                } else {
                    foreach ($v in $AllVersions) {
                        $Step = $v.version.Substring(0,3)
                        if (($Stepping -notcontains "$Step.0") -and ("$Step.0" -ne "$CurrentBase.0") -and ($Step -le $DesiredBase)) {
                            $Stepping += "$Step.0"
                        }
                    }
                    $Stepping += $Version
                }
                set-variable -name pacom -value $true -scope 1
                return $Stepping | sort
            } else {
                return $UpdateCheck.response.msg.line
            }
        }

        Function Download-Update ( [Parameter(Mandatory=$True)][String]$Version ) {
            $VersionInfo = Send-PaApiQuery -Op "<request><system><software><info></info></software></system></request>"
            if ($VersionInfo.response.status -eq "success") {
                $DesiredVersion = $VersionInfo.response.result."sw-updates".versions.entry | where { $_.version -eq "$Version" }
                if ($DesiredVersion.downloaded -eq "no") {
                    $Download = Send-PaApiQuery -Op "<request><system><software><download><version>$($DesiredVersion.version)</version></download></software></system></request>"
                    $job = [decimal]($Download.response.result.job)
                    $Status = Watch-PaJob -j $job -c "Downloading $($DesiredVersion.version)" -s $DesiredVersion.size -i 2 -p 1
                    if ($Status.response.result.job.result -eq "FAIL") {
                        return $Status.response.result.job.details.line
                    }
                    set-variable -name pacom -value $true -scope 1
                    return $Status
                } else {
                    set-variable -name pacom -value $true -scope 1
                    return "PanOS $Version already downloaded"
                }
            } else {
                throw $VersionInfo.response.msg.line
            }
        }

        Function Install-Update ( [Parameter(Mandatory=$True)][String]$Version ) {
            $VersionInfo = Send-PaApiQuery -Op "<request><system><software><info></info></software></system></request>"
            if ($VersionInfo.response.status -eq "success") {
                $DesiredVersion = $VersionInfo.response.result."sw-updates".versions.entry | where { $_.version -eq "$Version" }
                if ($DesiredVersion.downloaded -eq "no") { "PanOS $Version not downloaded" }
                if ($DesiredVersion.current -eq "no") {
                    $xpath = "<request><system><software><install><version>$Version</version></install></software></system></request>"
                    $Install = Send-PaApiQuery -Op $xpath
                    $Job = [decimal]($Install.response.result.job)
                    $Status = Watch-PaJob -j $job -c "Installing $Version" -i 2 -p 1
                    if ($Status.response.result.job.result -eq "FAIL") {
                        return $Status.response.result.job.details.line
                    }
                    set-variable -name pacom -value $true -scope 1
                    return $Status
                } else {
                    set-variable -name pacom -value $true -scope 1
                    return "PanOS $Version already installed"
                }
            } else {
                return $VersionInfo.response.msg.line
            }
        }

        Function Process-Query ( [String]$PaConnectionString ) {
            $pacom = $false
            while (!($pacom)) {
                if ($Version -eq "latest") {
                    $UpdateCheck = Send-PaApiQuery -Op "<request><system><software><check></check></software></system></request>"
                    if ($UpdateCheck.response.status -eq "success") {
                        $VersionInfo = Send-PaApiQuery -Op "<request><system><software><info></info></software></system></request>"
                        $Version = ($VersionInfo.response.result."sw-updates".versions.entry | where { $_.latest -eq "yes" }).version
                        if (!($Version)) { throw "no version marked as latest" }
                        $pacom = $true
                    } else {
                        return $UpdateCheck.response.msg.line
                    }
                }
            }

            $pacom = $false
            while (!($pacom)) {
                $Steps = Get-Stepping "$Version"
                $Steps
            }

            Write-host "it will take $($steps.count) upgrades to get to the current firmware"

            if (($Steps.count -gt 1) -and ($NoRestart)) {
                Throw "Must use -Restart for multiple steps"
            }
            
            $status = 0
            if ($DownloadOnly)      { $Total = ($Steps.count) } 
                elseif ($NoRestart) { $Total = ($Steps.count)*2 }
                else                { $Total = ($Steps.count)*3 }

            Write-Progress -Activity "Updating Software $Status/$Total" -Status "$($Status + 1)/$Total`: downloading $s" -id 1 -PercentComplete 0

            foreach ($s in $Steps) {
                $pacom = $false
                
                while (!($pacom)) {
                    $Download += Download-Update $s
                }
                $Status++
                $Progress = ($Status / $total) * 100
                Write-Progress -Activity "Updating Software $Status/$Total" -Status "$($Status + 1)/$Total`: downloading $s" -id 1 -PercentComplete $Progress
            }
            sleep 5

            if ($DownloadOnly) { return $Download }
            
            
            
            foreach ($s in $Steps) {
                $pacom = $false
                Write-Progress -Activity "Updating Software $Status/$Total" -Status "$($Status + 1)/$Total`: installing $s" -id 1 -PercentComplete $Progress
                while (!($pacom)) {
                    $pacom = $true
                    $Install = Install-Update $s
                }
                $Status++
                $Progress = ($Status / $total) * 100
                Write-Progress -Activity "Updating Software $Status/$Total" -Status "$($Status + 1)/$Total`: restarting $s" -id 1 -PercentComplete $Progress
                if (!($NoRestart)) {
                    Restart-PaSystem -i 2 -p 1
                    $Status++
                    $Progress = ($Status / $total) * 100
                    
                }
                Write-Progress -Activity "Updating Software $Status/$Total" -Status "Restarting" -id 1 -PercentComplete $Progress
            }
            Write-Progress -Activity "Updating Software $Status/$Total" -Status "Restarting" -id 1 -PercentComplete 100
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}


function Watch-PaJob {
    <#
    .EXTERNALHELP pspaloalto-help.xml
    .LINK
        https://github.com/zloeber/pspaloalto/tree/master/release/0.0.2/docs/Functions/Watch-PaJob.md
    #>

    Param (
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter(Mandatory=$True)]
        [Decimal]$Job,
        [Parameter()]
        [Decimal]$Size,
        [Parameter()]
        [Decimal]$Id,
        [Parameter()]
        [Decimal]$Parentid,
        [Parameter(Mandatory=$True)]
        [String]$Caption
    )

    BEGIN {
        Function Process-Query ( [String]$PaConnectionString ) {
            $cmd = "<show><jobs><id>$Job</id></jobs></show>"
            $JobStatus = Send-PaApiQuery -op "$cmd"
            $TimerStart = Get-Date
            
            $ProgressParams = @{}
            $ProgressParams.add("Activity",$Caption)
            if ($Id)       { $ProgressParams.add("Id",$Id) }
            if ($ParentId) { $ProgressParams.add("ParentId",$ParentId) }
            $ProgressParams.add("Status",$null)
            $ProgressParams.add("PercentComplete",$null)

            while ($JobStatus.response.result.job.status -ne "FIN") {
                $JobProgress = $JobStatus.response.result.job.progress
                $SizeComplete = ([decimal]$JobProgress * $Size)/100
                $Elapsed = ((Get-Date) - $TimerStart).TotalSeconds
                if ($Elapsed -gt 0) { $Speed = [math]::Truncate($SizeComplete/$Elapsed*1024) }
                $Status = $null
                if ($size)          { $Status = "$Speed`KB/s " } 
                $Status += "$($JobProgress)% complete"
                $ProgressParams.Set_Item("Status",$Status)
                $ProgressParams.Set_Item("PercentComplete",$JobProgress)
                Write-Progress @ProgressParams
                $JobStatus = Send-PaApiQuery -op "$cmd"
            }
            $ProgressParams.Set_Item("PercentComplete",100)
            Write-Progress @ProgressParams
            return $JobStatus
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}


## Post-Load Module code ##

# Use this variable for any path-sepecific actions (like loading dlls and such) to ensure it will work in testing and after being built
$MyModulePath = $(
    Function Get-ScriptPath {
        $Invocation = (Get-Variable MyInvocation -Scope 1).Value
        if($Invocation.PSScriptRoot) {
            $Invocation.PSScriptRoot
        }
        Elseif($Invocation.MyCommand.Path) {
            Split-Path $Invocation.MyCommand.Path
        }
        elseif ($Invocation.InvocationName.Length -eq 0) {
            (Get-Location).Path
        }
        else {
            $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
        }
    }

    Get-ScriptPath
)

# Load any plugins found in the plugins directory
if (Test-Path (Join-Path $MyModulePath 'plugins')) {
    Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName "Load.ps1")) {
            Invoke-Command -NoNewScope -ScriptBlock ([Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "Load.ps1") -Raw)}")) -ErrorVariable errmsg 2>$null
        }
    }
}

$ExecutionContext.SessionState.Module.OnRemove = {
    # Action to take if the module is removed
    # Unload any plugins found in the plugins directory
    if (Test-Path (Join-Path $MyModulePath 'plugins')) {
        Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName "UnLoad.ps1")) {
                Invoke-Command -NoNewScope -ScriptBlock ([Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "UnLoad.ps1") -Raw)}")) -ErrorVariable errmsg 2>$null
            }
        }
    }
}

$null = Register-EngineEvent -SourceIdentifier ( [System.Management.Automation.PsEngineEvent]::Exiting ) -Action {
    # Action to take if the whole pssession is killed
    # Unload any plugins found in the plugins directory
    if (Test-Path (Join-Path $MyModulePath 'plugins')) {
        Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName "UnLoad.ps1")) {
                Invoke-Command -NoNewScope -ScriptBlock [Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "UnLoad.ps1") -Raw)}") -ErrorVariable errmsg 2>$null
            }
        }
    }
}

# Bypass certificate issues
if (-not("dummy" -as [type])) {
    add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class Dummy {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(Dummy.ReturnTrue);
    }
}
"@
}

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [dummy]::GetDelegate()

# Use this in your scripts to check if the function is being called from your module or independantly.
$ThisModuleLoaded = $true

# Non-function exported public module members might go here.
#Export-ModuleMember -Variable SomeVariable -Function  *


