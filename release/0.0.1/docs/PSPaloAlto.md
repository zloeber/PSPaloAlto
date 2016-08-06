---
Module Name: PSPaloAlto
Module Guid: 00000000-0000-0000-0000-000000000000
Download Help Link: https://github.com/zloeber/PSPaloAlto/release/PSPaloAlto/docs/PSPaloAlto.md
Help Version: 0.0.1
Locale: en-US
---

# PSPaloAlto Module
## Description
Several functions for interfacing with the XLM interface of Palo Alto firewalls

## PSPaloAlto Cmdlets
### [Connect-PA](Connect-PA.md)
Creates connection string to a firewall for use with other functions in this module.

### [Convert-OutputForCSV](Convert-OutputForCSV.md)
Provides a way to expand collections in an object property prior
to being sent to Export-Csv.

### [Get-PAAddressGroup](Get-PAAddressGroup.md)
Returns information about an address group on the targeted PA.

### [Get-PaAddressObject](Get-PaAddressObject.md)
Returns information abbout address objects on the targeted PA.

### [Get-PAConnectionList](Get-PAConnectionList.md)
Returns list of connected Palo Altos.

### [Get-PaConnectionString](Get-PaConnectionString.md)
Creates a pa connection string for the specified credentials.

### [Get-PAEthernetInterface](Get-PAEthernetInterface.md)
Returns one or more Interface definitions from a Palo Alto firewall.

### [Get-PAHighAvailability](Get-PAHighAvailability.md)
Returns HA information about the desired PA.

### [Get-PALastResponse](Get-PALastResponse.md)
Returns last xml response returned from an operation.

### [Get-PALastURL](Get-PALastURL.md)
Returns last URL used for an operation.

### [Get-PALogJob](Get-PALogJob.md)
Formulate and send an api query to a PA firewall.

### [Get-PaNatPolicy](Get-PaNatPolicy.md)
Returns NAT Ruleset from Palo Alto firewall.

### [Get-PaSecurityPolicy](Get-PaSecurityPolicy.md)
Returns Security policies from Palo Alto firewall.

### [Get-PaSystemInfo](Get-PaSystemInfo.md)
Returns general information about the desired PA.

### [Get-PAZone](Get-PAZone.md)
Returns one or more zone definitions from a Palo Alto firewall.

### [Invoke-PACommit](Invoke-PACommit.md)
Invokes a configuratino commit to the PA.

### [New-PaLogJob](New-PaLogJob.md)
Create a new log request job.

### [Rename-PaAddressObject](Rename-PaAddressObject.md)
Renames existing address object on the targeted PA.

### [Rename-PANATPolicy](Rename-PANATPolicy.md)
Renames existing NAT policy on the targeted PA.

### [Rename-PaSecurityPolicy](Rename-PaSecurityPolicy.md)
Renames existing security policy on the targeted PA.

### [Send-PaApiQuery](Send-PaApiQuery.md)
Formulate and send an api query to a PA firewall.

### [Set-PaAddressObject](Set-PaAddressObject.md)
Updates or creates a new address object on the targeted PA.

### [Set-PaAddressObjectTag](Set-PaAddressObjectTag.md)
Updates an address object's assigned tags.

### [Set-PaSecurityRule](Set-PaSecurityRule.md)
Edits settings on a Palo Alto Security Rule

### [Test-PaConnection](Test-PaConnection.md)
Validates if the PA connection variable is set

### [Update-PaContent](Update-PaContent.md)
Updates Pa Content files.

### [Update-PaSoftware](Update-PaSoftware.md)
Updates PanOS System Software to desired level.

### [Watch-PaJob](Watch-PaJob.md)
Watch a given Jobs progress.


