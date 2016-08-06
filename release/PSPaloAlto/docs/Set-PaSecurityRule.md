---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# Set-PaSecurityRule
## SYNOPSIS
Edits settings on a Palo Alto Security Rule

## SYNTAX

```
Set-PaSecurityRule [[-PaConnection] <PSObject>] [[-Name] <String>] [[-Rename] <String>]
 [[-Description] <String>] [[-Tag] <String>] [[-SourceZone] <String>] [[-SourceAddress] <String>]
 [[-SourceUser] <String>] [[-HipProfile] <String>] [[-DestinationZone] <String>]
 [[-DestinationAddress] <String>] [[-Application] <String>] [[-Service] <String>] [[-UrlCategory] <String>]
 [[-SourceNegate] <String>] [[-DestinationNegate] <String>] [[-Action] <String>] [[-LogStart] <String>]
 [[-LogEnd] <String>] [[-LogForward] <String>] [[-Schedule] <String>] [[-Disabled] <String>]
 [[-ProfileGroup] <String>] [[-ProfileVirus] <String>] [[-ProfileVuln] <String>] [[-ProfileSpy] <String>]
 [[-ProfileUrl] <String>] [[-ProfileFile] <String>] [[-ProfileData] <String>] [[-QosDscp] <String>]
 [[-QosPrecedence] <String>] [[-DisableSri] <String>]
```

## DESCRIPTION
Edits settings on a Palo Alto Security Rule

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Needs to write some examples
```

## PARAMETERS

### -PaConnection
Specificies the Palo Alto connection string with address and apikey.
If ommitted, the currently connected PAs will be used

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

### -Name
Name of the rule

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rename
Rename the rule

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Rule descroption

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

### -Tag
Tag

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

### -SourceZone
SourceZone

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 6
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceAddress
SourceAddress

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 7
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceUser
SourceUser

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 8
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -HipProfile
HipProfile

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 9
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationZone
DestinationZone

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 10
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationAddress
DestinationAddress

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 11
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Application
Application

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 12
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Service
Service

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 13
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -UrlCategory
UrlCategory

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 14
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceNegate
SourceNegate

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 15
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationNegate
DestinationNegate

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 16
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action
Action

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 17
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogStart
LogStart

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 18
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogEnd
LogEnd

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 19
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogForward
LogForward

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 20
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Schedule
Schedule

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 21
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Disabled
Disabled

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 22
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileGroup
ProfileGroup

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 23
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileVirus
ProfileVirus

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 24
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileVuln
ProfileVuln

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 25
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileSpy
ProfileSpy

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 26
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileUrl
ProfileUrl

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 27
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileFile
ProfileFile

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 28
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileData
ProfileData

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 29
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -QosDscp
QosDscp

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 30
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -QosPrecedence
QosPrecedence

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 31
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisableSri
DisableSri

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 32
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

