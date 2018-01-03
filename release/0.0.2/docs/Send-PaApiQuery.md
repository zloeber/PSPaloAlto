---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Send-PaApiQuery

## SYNOPSIS
Formulate and send an api query to a PA firewall.

## SYNTAX

### config
```
Send-PaApiQuery [-Config] <String> -XPath <String> [-Element <String>] [-Member <String>] [-NewName <String>]
 [-CloneFrom <String>] [-MoveWhere <String>] [-MoveDestination <String>] [-PaConnection <String>]
```

### op
```
Send-PaApiQuery [-Op] <String> [-PaConnection <String>]
```

### report
```
Send-PaApiQuery [-Report] <String> [-ReportName <String>] [-Rows <Decimal>] [-Period <String>]
 [-StartTime <String>] [-EndTime <String>] [-PaConnection <String>]
```

### export
```
Send-PaApiQuery [-Export] <String> [-From <String>] [-To <String>] [-DlpPassword <String>]
 [-CertificateName <String>] [-CertificateFormat <String>] [-ExportPassPhrase <String>] [-TsAction <String>]
 [-Job <Decimal>] -ExportFile <String> [-PaConnection <String>]
```

### import
```
Send-PaApiQuery [-Import] <String> [-ImportFile] <String> [-ImportCertificateName <String>]
 [-ImportCertificateFormat <String>] [-ImportPassPhrase <String>] [-ImportProfile <String>]
 [-ImportWhere <String>] [-PaConnection <String>]
```

### log
```
Send-PaApiQuery [-Log] <String> [-LogQuery <String>] [-NumberLogs <Decimal>] [-SkipLogs <String>]
 [-LogAction <String>] [-LogJob <Decimal>] [-PaConnection <String>]
```

### userid
```
Send-PaApiQuery [-UserId] <String> [-PaConnection <String>]
```

### commit
```
Send-PaApiQuery [-Commit] [-Force] [-Partial <String>] [-PaConnection <String>]
```

## DESCRIPTION
Formulate and send an api query to a PA firewall.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -Config
Type of configuration query to send: show, get, set, edit, delete, rename, clone, or move.

```yaml
Type: String
Parameter Sets: config
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -XPath
XPath to query

```yaml
Type: String
Parameter Sets: config
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Element
Element to query

```yaml
Type: String
Parameter Sets: config
Aliases: e

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Member
Member to query

```yaml
Type: String
Parameter Sets: config
Aliases: m

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewName
NewName

```yaml
Type: String
Parameter Sets: config
Aliases: nn

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CloneFrom
CloneFrom

```yaml
Type: String
Parameter Sets: config
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MoveWhere
MoveWhere

```yaml
Type: String
Parameter Sets: config
Aliases: mw

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MoveDestination
MoveDestination

```yaml
Type: String
Parameter Sets: config
Aliases: dst

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Op
Operator to use

```yaml
Type: String
Parameter Sets: op
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Report
Report

```yaml
Type: String
Parameter Sets: report
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportName
ReportName

```yaml
Type: String
Parameter Sets: report
Aliases: rn

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rows
Rows

```yaml
Type: Decimal
Parameter Sets: report
Aliases: r

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Period
Period

```yaml
Type: String
Parameter Sets: report
Aliases: p

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
StartTime

```yaml
Type: String
Parameter Sets: report
Aliases: start

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
EndTime

```yaml
Type: String
Parameter Sets: report
Aliases: end

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Export
Export

```yaml
Type: String
Parameter Sets: export
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -From
From

```yaml
Type: String
Parameter Sets: export
Aliases: f

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -To
To

```yaml
Type: String
Parameter Sets: export
Aliases: t

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DlpPassword
DlpPassword

```yaml
Type: String
Parameter Sets: export
Aliases: dp

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateName
CertificateName

```yaml
Type: String
Parameter Sets: export
Aliases: ecn

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateFormat
CertificateFormat

```yaml
Type: String
Parameter Sets: export
Aliases: ecf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExportPassPhrase
ExportPassPhrase

```yaml
Type: String
Parameter Sets: export
Aliases: epp

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TsAction
TsAction

```yaml
Type: String
Parameter Sets: export
Aliases: ta

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Job
Job

```yaml
Type: Decimal
Parameter Sets: export
Aliases: j

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExportFile
ExportFile

```yaml
Type: String
Parameter Sets: export
Aliases: ef

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Import
Import

```yaml
Type: String
Parameter Sets: import
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportFile
ImportFile

```yaml
Type: String
Parameter Sets: import
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportCertificateName
ImportCertificateName

```yaml
Type: String
Parameter Sets: import
Aliases: icn

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportCertificateFormat
ImportCertificateFormat

```yaml
Type: String
Parameter Sets: import
Aliases: icf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportPassPhrase
ImportPassphrase

```yaml
Type: String
Parameter Sets: import
Aliases: ipp

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportProfile
ImportProfile

```yaml
Type: String
Parameter Sets: import
Aliases: ip

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportWhere
ImportWhere

```yaml
Type: String
Parameter Sets: import
Aliases: wh

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Log
Log

```yaml
Type: String
Parameter Sets: log
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogQuery
LogQuery

```yaml
Type: String
Parameter Sets: log
Aliases: q

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NumberLogs
NumberLogs

```yaml
Type: Decimal
Parameter Sets: log
Aliases: nl

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipLogs
SkipLogs

```yaml
Type: String
Parameter Sets: log
Aliases: sl

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogAction
LogAction

```yaml
Type: String
Parameter Sets: log
Aliases: la

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogJob
LogJob

```yaml
Type: Decimal
Parameter Sets: log
Aliases: lj

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
UserId

```yaml
Type: String
Parameter Sets: userid
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Commit
Commit

```yaml
Type: SwitchParameter
Parameter Sets: commit
Aliases: 

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force

```yaml
Type: SwitchParameter
Parameter Sets: commit
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Partial
Partial

```yaml
Type: String
Parameter Sets: commit
Aliases: part

Required: False
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

