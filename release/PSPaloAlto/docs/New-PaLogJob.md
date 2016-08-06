---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# New-PaLogJob
## SYNOPSIS
Create a new log request job.

## SYNTAX

```
New-PaLogJob [-Type] <String> [-Query] <String> [[-NumberLogs] <Decimal>] [[-Skip] <String>]
 [[-PaConnection] <String>]
```

## DESCRIPTION
Create a new log request job.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -Type
Type of log to request.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Query
Log filter or query to use.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -NumberLogs
Number of logs to retrieve

```yaml
Type: Decimal
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip
Skip logs with this string.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, current connections will be used

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

