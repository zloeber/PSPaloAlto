---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# Get-PaAddressObject
## SYNOPSIS
Returns information abbout address objects on the targeted PA.

## SYNTAX

```
Get-PaAddressObject [[-Name] <String>] [[-PaConnection] <PSObject>] [[-Target] <String>]
```

## DESCRIPTION
Returns information abbout address objects on the targeted PA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PaAddressObject
```

Description
-----------
Returns information about all defined address objects.

## PARAMETERS

### -Name
Name of an address object to retrieve.
If not specified all address objects will be listed.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: pc

Required: False
Position: 2
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Target
Specify either vsys1 (the local device configuration) or panorama configurations

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: Vsys1
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

