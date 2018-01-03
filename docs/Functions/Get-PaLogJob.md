---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Get-PALogJob

## SYNOPSIS
Formulate and send an api query to a PA firewall.

## SYNTAX

```
Get-PALogJob [-Action] <String> [-Job] <String> [[-PaConnection] <String>]
```

## DESCRIPTION
Formulate and send an api query to a PA firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PALogJob -Action 'Get' -Job 'job1'
```

## PARAMETERS

### -Action
Type of job, either 'get' or 'finish'

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

### -Job
Job to retrieve

```yaml
Type: String
Parameter Sets: (All)
Aliases: j

Required: True
Position: 2
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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

