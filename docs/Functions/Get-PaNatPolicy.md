---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Get-PaNatPolicy

## SYNOPSIS
Returns NAT Ruleset from Palo Alto firewall.

## SYNTAX

```
Get-PaNatPolicy [[-Rule] <String>] [[-PaConnection] <String>] [[-Target] <String>]
```

## DESCRIPTION
Returns NAT Ruleset from Palo Alto firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PaNatPolicy
```

Description
-----------
Return all information about all nat rules found, including the order they are found in.

## PARAMETERS

### -Rule
Query for specific rule by name.
Order will not be returned if this parameter is specified.

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
Type: String
Parameter Sets: (All)
Aliases: pc

Required: False
Position: 2
Default value: None
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

