---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Get-PaSecurityPolicy

## SYNOPSIS
Returns Security policies from Palo Alto firewall.

## SYNTAX

```
Get-PaSecurityPolicy [[-Rule] <String>] [[-PaConnection] <String>] [[-Target] <String>] [-Candidate]
```

## DESCRIPTION
Returns NAT Ruleset from Palo Alto firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PaSecurityPolicy
```

Description
-----------
Return all information about all security rules found, including the order they are found in.

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

### -Candidate
Query the candidate configuration.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

