---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# Get-PaConnectionString
## SYNOPSIS
Creates a pa connection string for the specified credentials.

## SYNTAX

```
Get-PaConnectionString [-Address] <String> [-Cred] <PSCredential>
```

## DESCRIPTION
Creates a pa connection string for the specified credentials.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Connect-Pa 192.168.1.1
```

https://192.168.1.1/api/?key=LUFRPT1SanJaQVpiNEg4TnBkNGVpTmRpZTRIamR4OUE9Q2lMTUJGREJXOCs3SjBTbzEyVSt6UT01

      c:\PS\> Get-PaConnectionString -Address 192.168.1.1 -Cred (Get-Credential)

      ConnectionString                 ApiKey                           Address
      ----------------                 ------                           -------
      https://192.168.1.1/api/?key=...
LUFRPT1SanJaQVpiNEg4TnBkNGVpT...
192.168.1.1

## PARAMETERS

### -Address
Specifies the IP or FQDN of the system to connect to.

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

### -Cred
Specifiy a PSCredential object, If no credential object is specified, the user will be prompted.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Credential

Required: True
Position: 2
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### PSObject

## NOTES

## RELATED LINKS

