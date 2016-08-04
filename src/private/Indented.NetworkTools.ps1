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

# SIG # Begin signature block
# MIIPkQYJKoZIhvcNAQcCoIIPgjCCD34CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYwScto8p7BMqNGU8XHrrziHp
# f+2gggzGMIIGTjCCBTagAwIBAgICDfcwDQYJKoZIhvcNAQELBQAwgYwxCzAJBgNV
# BAYTAklMMRYwFAYDVQQKEw1TdGFydENvbSBMdGQuMSswKQYDVQQLEyJTZWN1cmUg
# RGlnaXRhbCBDZXJ0aWZpY2F0ZSBTaWduaW5nMTgwNgYDVQQDEy9TdGFydENvbSBD
# bGFzcyAyIFByaW1hcnkgSW50ZXJtZWRpYXRlIE9iamVjdCBDQTAeFw0xNDA0MTUw
# MjM4MjBaFw0xNjA0MTQxMzM5NDhaMHsxCzAJBgNVBAYTAkdCMRYwFAYDVQQIEw1I
# ZXJ0Zm9yZHNoaXJlMRQwEgYDVQQHEwtCb3JlaGFtd29vZDEZMBcGA1UEAxMQQ2hy
# aXN0b3BoZXIgRGVudDEjMCEGCSqGSIb3DQEJARYUY2hyaXNAaW5kZW50ZWQuY28u
# dWswggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC8qgMvi3CrIaYXMuF4
# hsyqH/Az5GbHm5gAyqORwjfYeT7LNb/hQuSr8O+jt39lHem30Yhn++jPWVGGQsYk
# 7RlSqXQ1nUbbJomqNxnMiat7OqnOOmWxjGgwDCfCXDqlgT+RK3J1+RvRa9ZDOkcA
# zjO6fsg4wBJd6+F1lAz4IOTuab/kJum4TGXQAUfjO1Em7EcrmA6Xu0pdkunYtsKn
# iZGDN8Zpu7Km/hSMnHRALjblFAiT8U4b9VhJqRyiOWmPWlHJn/a/qSexwOnP667B
# 0ydYL/iraNel1sKhniwOe8wMsUM5CF1+zL7WCS1Uhw16LvykbS5+LPSaBLFGY8I0
# 9v3FAgMBAAGjggLIMIICxDAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAuBgNV
# HSUBAf8EJDAiBggrBgEFBQcDAwYKKwYBBAGCNwIBFQYKKwYBBAGCNwoDDTAdBgNV
# HQ4EFgQUP5UsJQgs37GI2zeMv/mp8Ri6vHMwHwYDVR0jBBgwFoAU0E4PQJlsuEsZ
# bzsouODjiAc0qrcwggFMBgNVHSAEggFDMIIBPzCCATsGCysGAQQBgbU3AQIDMIIB
# KjAuBggrBgEFBQcCARYiaHR0cDovL3d3dy5zdGFydHNzbC5jb20vcG9saWN5LnBk
# ZjCB9wYIKwYBBQUHAgIwgeowJxYgU3RhcnRDb20gQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkwAwIBARqBvlRoaXMgY2VydGlmaWNhdGUgd2FzIGlzc3VlZCBhY2NvcmRp
# bmcgdG8gdGhlIENsYXNzIDIgVmFsaWRhdGlvbiByZXF1aXJlbWVudHMgb2YgdGhl
# IFN0YXJ0Q29tIENBIHBvbGljeSwgcmVsaWFuY2Ugb25seSBmb3IgdGhlIGludGVu
# ZGVkIHB1cnBvc2UgaW4gY29tcGxpYW5jZSBvZiB0aGUgcmVseWluZyBwYXJ0eSBv
# YmxpZ2F0aW9ucy4wNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5zdGFydHNz
# bC5jb20vY3J0YzItY3JsLmNybDCBiQYIKwYBBQUHAQEEfTB7MDcGCCsGAQUFBzAB
# hitodHRwOi8vb2NzcC5zdGFydHNzbC5jb20vc3ViL2NsYXNzMi9jb2RlL2NhMEAG
# CCsGAQUFBzAChjRodHRwOi8vYWlhLnN0YXJ0c3NsLmNvbS9jZXJ0cy9zdWIuY2xh
# c3MyLmNvZGUuY2EuY3J0MCMGA1UdEgQcMBqGGGh0dHA6Ly93d3cuc3RhcnRzc2wu
# Y29tLzANBgkqhkiG9w0BAQsFAAOCAQEAD7BiUmVY3C8HGt488or/G3ch85ru/iA2
# LUS6AErbJsy/ocdIa1QVLb65r9+ioarwpShqhqUCWaJjI0Cx8Afrp6/WXsL807Ud
# 1P1sdfNGkVhewoVngzaV4JARgX9V/4E4BA8G1hBuFhc0CDrzj5tuhTarF+BmpRQ/
# X6B39m1mUMVGH0VDgzJptdF9CQayjG7fd9fYy6e92hxi2vZPeFf8HdEqFCiIhiSn
# /EZBvonC9/XgFqwPtxHPWtngo2Odl8YFWw047zxF7ODVziodzHUapS1v45QQug/K
# scqsn6Im2JG29caDOBPklC92dTXj/w56Crj6/8mlMTHJ+Km/NZCxHjCCBnAwggRY
# oAMCAQICASQwDQYJKoZIhvcNAQEFBQAwfTELMAkGA1UEBhMCSUwxFjAUBgNVBAoT
# DVN0YXJ0Q29tIEx0ZC4xKzApBgNVBAsTIlNlY3VyZSBEaWdpdGFsIENlcnRpZmlj
# YXRlIFNpZ25pbmcxKTAnBgNVBAMTIFN0YXJ0Q29tIENlcnRpZmljYXRpb24gQXV0
# aG9yaXR5MB4XDTA3MTAyNDIyMDE0NloXDTE3MTAyNDIyMDE0NlowgYwxCzAJBgNV
# BAYTAklMMRYwFAYDVQQKEw1TdGFydENvbSBMdGQuMSswKQYDVQQLEyJTZWN1cmUg
# RGlnaXRhbCBDZXJ0aWZpY2F0ZSBTaWduaW5nMTgwNgYDVQQDEy9TdGFydENvbSBD
# bGFzcyAyIFByaW1hcnkgSW50ZXJtZWRpYXRlIE9iamVjdCBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAMojiyI1HpqgGzydSdA/DJc4Fim6+H2JW0VY
# 74Rw7X4RTekUMatD400MUYFs8BUDSiQnVOX7SqDOTeGEoyHemTWr3EmuvzHFZ4Qw
# EJvvB9x1qA9N9DVTsW44A/yIdx2ld/8/defZ578sUBHJEWX6SQdin5Omh6ltyZ0r
# 0Xvl1WUrnw1Qnv77cRkhMCgmja7C3PaW6FKGCAt6Ms1qFE2eufnNB+KWkfHPHiv5
# gvdeJgaOjdHUOddv25EnWnmPWGkKRrVv4f1vxZG0EU97AqbbS1ZSI55LmOK/fs76
# oU6D48XHw2BH/lw/FRpAKpXvAGvIUPjNahnUIwMnvDs21blDsO8CAwEAAaOCAekw
# ggHlMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTQ
# Tg9AmWy4SxlvOyi44OOIBzSqtzAfBgNVHSMEGDAWgBROC+8apEBbpRdphzDKNGhD
# 0EGu8jA9BggrBgEFBQcBAQQxMC8wLQYIKwYBBQUHMAKGIWh0dHA6Ly93d3cuc3Rh
# cnRzc2wuY29tL3Nmc2NhLmNydDBbBgNVHR8EVDBSMCegJaAjhiFodHRwOi8vd3d3
# LnN0YXJ0c3NsLmNvbS9zZnNjYS5jcmwwJ6AloCOGIWh0dHA6Ly9jcmwuc3RhcnRz
# c2wuY29tL3Nmc2NhLmNybDCBgAYDVR0gBHkwdzB1BgsrBgEEAYG1NwECATBmMC4G
# CCsGAQUFBwIBFiJodHRwOi8vd3d3LnN0YXJ0c3NsLmNvbS9wb2xpY3kucGRmMDQG
# CCsGAQUFBwIBFihodHRwOi8vd3d3LnN0YXJ0c3NsLmNvbS9pbnRlcm1lZGlhdGUu
# cGRmMBEGCWCGSAGG+EIBAQQEAwIAATBQBglghkgBhvhCAQ0EQxZBU3RhcnRDb20g
# Q2xhc3MgMiBQcmltYXJ5IEludGVybWVkaWF0ZSBPYmplY3QgU2lnbmluZyBDZXJ0
# aWZpY2F0ZXMwDQYJKoZIhvcNAQEFBQADggIBAHJzCwN1WjeDiBPZeEE+ThLWcuTw
# cgYrd6B4qkKYFREKOwx0bI1w+R/yMk4r6TIpGmnkcSL/eW2kXeIaFHDMA4+CSIwt
# 1gPRaDRVd9UjJYxGWuuhvEUBAnTEkrn4Hw2LtV0PnFCsYQ9xLSxhnBRo4zC+xEL9
# iKJe+NaxLMnF8CF3K8sXojG1Nkz4u193pW8EDHOCRZSeAcvRYQc7mQdQ1drDdoqx
# lWwtxv9fktnaDw4y9QmhJcEWv09KpKtr7z8VIK8gKAqaVBSlYsOcqBmAvs9RmnrF
# loj9XhSgC9MCOyIEry81N8tVae77GGsTlQambXmxU1kR7V4wrBa60AZ4LdHd90G0
# ESOZsIMxKe1yfcbuXekVVjOEz0VLHfgw2aQR5vZrM74vYFRW9mRu6kUVwkqsrOPr
# vzSwT214v5v5VNNHDg0E5Qv3rsI5PR0LUa10P86rASUulCfnixsNajn4/h1QZf2U
# KX6C5OyKFpUUL0S9bO6IqxGqj2VCFmP4K16va+owygKdy2XSkKTzp56ILapVOH+/
# 5C4xCYa63PfJqzlplTCvwbhUQH0OaA1DJ1ZgswMyzIynxnFVv4jHsONcn4YCm8KX
# 85tywa9Wb/qRAYHIFuqJ0S0gJ91xzNHjbc/gJMR+q0X+gdpmISxBBi2qR/EdQDAK
# OAW1RTmUeZF3DAsKMYICNTCCAjECAQEwgZMwgYwxCzAJBgNVBAYTAklMMRYwFAYD
# VQQKEw1TdGFydENvbSBMdGQuMSswKQYDVQQLEyJTZWN1cmUgRGlnaXRhbCBDZXJ0
# aWZpY2F0ZSBTaWduaW5nMTgwNgYDVQQDEy9TdGFydENvbSBDbGFzcyAyIFByaW1h
# cnkgSW50ZXJtZWRpYXRlIE9iamVjdCBDQQICDfcwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMga
# 450fHSAfHE1EBY7xsh3EMyMXMA0GCSqGSIb3DQEBAQUABIIBAFOwRT588wSx52L0
# 9ztv3idveNP5bJzgqcJzNgRso2lxCES/iDGdoevYK3aAQ18OtvyEw2hegwfBia7i
# 7iVxEzn9d8uSudx7DUWVP4nwOP7x/DXF8bB2etthIEXCWuVjU3DETP0aHaW5hi2K
# IohDmB6GpJV0KzDv7sWWqK8S5Rc11I114uW/hGmb63wploi9UwEeQtL+EacGdkU8
# 9CN+GuydZrKkP5/K7ncIPCWEp0T+CZLbN+4cB79hoZoMs6ZXEUDgWYK1Vn53/X7E
# B0ZlbzFs9bFNFNnLbQmBOm+D4xHTZwI7kcf7mphDDUebhyB6b8GF3aCAUsKpdnaH
# cBvTMcQ=
# SIG # End signature block
