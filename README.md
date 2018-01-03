# PowerAlto Revised (PSPaloAlto)

This is a powershell module for interacting more easily with the Palo Alto line of firewalls using their XML API interface.

[TOC]

## Introduction
Firstly the original project this is forked from can be located **[Here](http://brianaddicks.github.com/poweralto)**

This updated version continues where the author left off and improves the module in several ways:
- There were some outside dependencies required to get the module to work properly. These are directly bundled into this fork.
- I've made several other changes to get more of what I wanted from some Palos that I needed to audit as well. I've tried to pull out each major type of item into its own set of commands (get/set/rename). So there are now cmdlets for getting address objects, address groups, zones, security and nat policies.
- Added a cmdlet to get high availability information.
- Updated parameters and many functions to be able to target both the local (vsys1) and panorama configurations.
- Stripped out sub-functions into their own private functions.
- Added commands for showing the last query results in their native xml format as well as the last query string which was sent.
- Added multiple connection capabilities to update or get information from several firewalls at once.

The XML API is too huge to create cmdlets for everything but the base work is here for anyone to expand upon to suit their own needs. That is, after all, exactly what I did!

## Examples
I personally used this module to standardize the object and policy names across several Palos in my environment but you can use this for auditing purposes or really whatever you want to use it for (see Customization further on)

```
Import-Module .\PowerAlto.psm1
$cred = Get-Credential

# Connect to the PA at 192.168.1.1
Connect-PA -Address '192.168.1.1' -Cred $cred

# Connect to the PA at 192.168.1.2, append to the list of connections
# Now both 192.168.1.1 and 192.168.1.2 will be queried with EVERY call you make (Be careful!)
Connect-PA -Address '192.168.1.1' -Cred $cred -Append

# List the current connection strings to confirm
Get-ConnectionList

# Display the current zones
Get-PAZone

# Display the current address objects
Get-PAAddressObject

# Rename an address object (note there is a 31 character limit on all named objects!)
Rename-PAAddressObject -Name 'My stupidly named address object' -NewName 'addr_10.0.1.1'

# Commit your changes, this can take a bit of time *sigh*...
Invoke-PACommit
```

## Customization
You can very easily test queries to your palo altos using this module and the (largely unchanged) 'Send-PaAPIQuery' function. How do you know what to send? Well that is part of the suckiness of XML insomuch that you may have to do a bit of poking around to get the exact syntax. This is a bit easier with the xml browser you can access at any Palo Alto firewall's web interface at https://x.x.x.x/api/

## Notes
- Do yourself a favor and use this module against a non-production system first please? I've only really tested and used the cmdlets I've needed to meet my own demands. There are several others included which I've really not even looked at.
- XML kind of sucks. Most of these functions only pull a small subsection of data returned from the XML API. Use the Get-PALastResult often to get more data and Get-PALastURL to help craft new API calls of your own.
- I've noticed in newer PANOS versions that the stored data includes more attributes per element that track who made changes and when they were made. Most of the code accounts for this but i may have missed a few here and there. If results are not populating as you'd expect try updating the query with Text-Query or Member-Query private functions along with the element and attribute you are looking to return.
- I've included Boe Prox's 'Convert-OutputForCSV' function in the public functions to more easily export the data with export-csv. So to export all the policy rules:

    `Get-PASecurityPolicy | Convert-OutputForCSV | Export-CSV -NoTypeInformation 'C:\temp\policyrules.csv'`

- I'm not going to lie, the chances that I'm going to take this project and update it on a regular basis is very slim. If you want something added you will have to do it yourself or nag Palo Alto to release an official module. ;)

## Credits
Original project: **[PowerAlto](http://brianaddicks.github.com/poweralto)**
Indented.NetworkTools.ps1: **[Indented Site](http://www.indented.co.uk) **




