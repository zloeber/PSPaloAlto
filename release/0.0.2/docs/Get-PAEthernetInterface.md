---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Get-PAEthernetInterface

## SYNOPSIS
Returns one or more Interface definitions from a Palo Alto firewall.

## SYNTAX

```
Get-PAEthernetInterface [[-Name] <String>] [[-PaConnection] <PSObject>] [-Aggregate]
```

## DESCRIPTION
Returns one or more Interface definitions from a Palo Alto firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PAEthernetInterface
```

Description
-------------
Returns information about all defined Interfaces.

## PARAMETERS

### -Name
Query for specific interface by name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Aggregate
Target aggregate interfaces.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

