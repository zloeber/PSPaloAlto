---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# New-PaAddressObject

## SYNOPSIS
Creates a new address object on the targeted PA.

## SYNTAX

```
New-PaAddressObject [-Name] <String> [-IPNetmask] <String> [[-Description] <String>]
 [[-PaConnection] <PSObject>] [[-Target] <String>]
```

## DESCRIPTION
Creates a new address object on the targeted PA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-PaAddressObject -Name 'addr_ext_4.2.2.2' -IPNetmask '4.2.2.2' -Description 'Test Address Object'
```

## PARAMETERS

### -Name
Name of address object

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPNetmask
IP netmask to set on the object

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

### -Description
Description of address object

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
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
Position: 4
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
Position: 5
Default value: Vsys1
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

