---
external help file: pspaloalto-help.xml
Module Name: pspaloalto
online version: 
schema: 2.0.0
---

# Convert-OutputForCSV

## SYNOPSIS
Provides a way to expand collections in an object property prior
to being sent to Export-Csv.

## SYNTAX

```
Convert-OutputForCSV [[-InputObject] <PSObject>] [[-OutputPropertyType] <String>]
```

## DESCRIPTION
Provides a way to expand collections in an object property prior
to being sent to Export-Csv.
This helps to avoid the object type
from being shown such as system.object\[\] in a spreadsheet.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$Output = 'PSComputername','IPAddress','DNSServerSearchOrder'
```

Get-WMIObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" |
Select-Object $Output | Convert-OutputForCSV | 
Export-Csv -NoTypeInformation -Path NIC.csv    

Description
-----------
Using a predefined set of properties to display ($Output), data is collected from the 
Win32_NetworkAdapterConfiguration class and then passed to the Convert-OutputForCSV
funtion which expands any property with a collection so it can be read properly prior
to being sent to Export-Csv.
Properties that had a collection will be viewed as a stack
in the spreadsheet. 
 


Requires -Version 3.0

## PARAMETERS

### -InputObject
The object that will be sent to Export-Csv

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -OutputPropertyType
This determines whether the property that has the collection will be
shown in the CSV as a comma delimmited string or as a stacked string.

Possible values:
Stack
Comma

Default value is: Stack

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: Stack
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Name: Convert-OutputForCSV
Author: Boe Prox
Created: 24 Jan 2014
Version History:
    1.1 - 02 Feb 2014
        -Removed OutputOrder parameter as it is no longer needed; inputobject order is now respected 
        in the output object
    1.0 - 24 Jan 2014
        -Initial Creation

## RELATED LINKS

