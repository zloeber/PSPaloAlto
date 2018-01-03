---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Set-PaAddressObjectTag

## SYNOPSIS
Updates an address object's assigned tags.

## SYNTAX

```
Set-PaAddressObjectTag [-Name] <String> [-Tags] <String> [-PaConnection <PSObject>] [-Target <String>]
```

## DESCRIPTION
Updates an address object's assigned tags.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -Name
Name of object to update

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Tags
Tags to assign

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, current connections will be used

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Target
Configuration to target, either vsys1 (default) or panorama

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: Vsys1
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

