---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# Watch-PaJob
## SYNOPSIS
Watch a given Jobs progress.

## SYNTAX

```
Watch-PaJob [[-PaConnection] <PSObject>] [-Job] <Decimal> [[-Size] <Decimal>] [[-Id] <Decimal>]
 [[-Parentid] <Decimal>] [-Caption] <String>
```

## DESCRIPTION
Watch a given Jobs progress.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, the current connections will be used

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Job
Job to watch

```yaml
Type: Decimal
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Size
Size

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

### -Id
Id

```yaml
Type: Decimal
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parentid
Parentid

```yaml
Type: Decimal
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Caption
Caption

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 6
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

