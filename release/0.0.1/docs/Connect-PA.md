---
external help file: PSPaloAlto-help.xml
online version: 
schema: 2.0.0
---

# Connect-PA
## SYNOPSIS
Creates connection string to a firewall for use with other functions in this module.

## SYNTAX

```
Connect-PA [-Address] <String> [-Cred] <PSCredential> [-Append]
```

## DESCRIPTION
Creates connection string to a firewall for use with other functions in this module.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Connect-Pa -Address 192.168.1.1 -Cred $PSCredential -Append
```

Description
-----------
Creates a connection object to 192.168.1.1 using the credential stored in $PSCredential and adds it to the list of firewalls which will be processed.

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
Aliases: 

Required: True
Position: 2
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -Append
Append this connection to the list of connections in the array.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

