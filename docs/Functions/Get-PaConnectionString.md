---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Get-PaConnectionString

## SYNOPSIS
Connects to a Palo Alto firewall and generates a connection object for use with this module.

## SYNTAX

```
Get-PaConnectionString [-Address] <String> [-Cred] <PSCredential>
```

## DESCRIPTION
Connects to a Palo Alto firewall and returns an connection object that includes the API key, connection string, and address.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Connect-Pa 192.168.1.1
```

https://192.168.1.1/api/?key=LUFRPT1SanJaQVpiNEg4TnBkNGVpTmRpZTRIamR4OUE9Q2lMTUJGREJXOCs3SjBTbzEyVSt6UT01

c:\PS\> $global:PaConnectionArray

ConnectionString                 ApiKey                           Address
----------------                 ------                           -------
https://192.168.1.1/api/?key=...
LUFRPT1SanJaQVpiNEg4TnBkNGVpT...
192.168.1.1

### -------------------------- EXAMPLE 2 --------------------------
```
Connect-Pa -Address 192.168.1.1 -Cred $PSCredential
```

https://192.168.1.1/api/?key=LUFRPT1SanJaQVpiNEg4TnBkNGVpTmRpZTRIamR4OUE9Q2lMTUJGREJXOCs3SjBTbzEyVSt6UT01

## PARAMETERS

### -Address
Specifies the IP or FQDN of the system to connect to.

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

### -Cred
Specifiy a PSCredential object, If no credential object is specified, the user will be prompted.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Credential

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### PSObject

## NOTES

## RELATED LINKS

