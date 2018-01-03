---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Get-PAZone

## SYNOPSIS
Returns one or more zone definitions from a Palo Alto firewall.

## SYNTAX

```
Get-PAZone [[-Name] <String>] [[-PaConnection] <String>] [[-Target] <String>]
```

## DESCRIPTION
Returns one or more zone definitions from a Palo Alto firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PAZone -Name 'Internal'
```

Description
-----------
Returns information about the zone named 'Internal' if it exists

## PARAMETERS

### -Name
Query for specific zone by name.

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
If ommitted, current connections will be used

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
Starget the device (vsys1) or panorama pushed rules (panorama)

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

