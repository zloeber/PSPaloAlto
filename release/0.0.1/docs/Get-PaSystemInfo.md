---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# Get-PaSystemInfo
## SYNOPSIS
Returns general information about the desired PA.

## SYNTAX

```
Get-PaSystemInfo [[-PaConnection] <PSObject>]
```

## DESCRIPTION
Returns the version number of various components of a Palo Alto firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PaSystemInfo
```

## PARAMETERS

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: pc

Required: False
Position: 1
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

