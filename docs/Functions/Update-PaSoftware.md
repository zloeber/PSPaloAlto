---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Update-PaSoftware

## SYNOPSIS
Updates PanOS System Software to desired level.

## SYNTAX

```
Update-PaSoftware [[-PaConnection] <String>] [-Version] <String> [-DownloadOnly] [-NoRestart]
```

## DESCRIPTION
Updates PanOS System Software to desired level. 
Can do multiple stepped updated, download only and restart or not.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
NA
```

## PARAMETERS

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, all connection strings stored in the module local variable from Connect-PA will be used.

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

### -Version
Version of the software to update to

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

### -DownloadOnly
Only download the available update

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoRestart
Do not restart the device after updating.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

