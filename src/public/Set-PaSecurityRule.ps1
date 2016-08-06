function Set-PaSecurityRule {
	<#
	.SYNOPSIS
		Edits settings on a Palo Alto Security Rule
	.DESCRIPTION
		Edits settings on a Palo Alto Security Rule
	.EXAMPLE
        Needs to write some examples
    .PARAMETER Name
        Name of the rule
    .PARAMETER Rename
        Rename the rule
    .PARAMETER Description
        Rule descroption
    .PARAMETER Tag
        Tag
    .PARAMETER SourceZone
        SourceZone
    .PARAMETER SourceAddress
    SourceAddress
    .PARAMETER SourceUser
    SourceUser
    .PARAMETER HipProfile
    HipProfile
    .PARAMETER DestinationZone
    DestinationZone
    .PARAMETER DestinationAddress
    DestinationAddress
    .PARAMETER Application
    Application
    .PARAMETER Service
    Service
    .PARAMETER UrlCategory
    UrlCategory
    .PARAMETER SourceNegate
    SourceNegate
    .PARAMETER DestinationNegate
    DestinationNegate
    .PARAMETER Action
    Action
    .PARAMETER LogStart
    LogStart
    .PARAMETER LogEnd
    LogEnd
    .PARAMETER LogForward
    LogForward
    .PARAMETER Schedule
    Schedule
    .PARAMETER Disabled
    Disabled
    .PARAMETER ProfileGroup
    ProfileGroup
    .PARAMETER ProfileVirus
    ProfileVirus
    .PARAMETER ProfileVuln
    ProfileVuln
    .PARAMETER ProfileSpy
    ProfileSpy
    .PARAMETER ProfileUrl
    ProfileUrl
    .PARAMETER ProfileFile
    ProfileFile
    .PARAMETER ProfileData
    ProfileData
    .PARAMETER QosDscp
    QosDscp
    .PARAMETER QosPrecedence
    QosPrecedence
    .PARAMETER DisableSri
    DisableSri
    .PARAMETER PaConnection
		Specificies the Palo Alto connection string with address and apikey. If ommitted, the currently connected PAs will be used
	#>
    
    Param (
        [Parameter()]
        [PSObject]$PaConnection,
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$Rename,
        [Parameter()]
        [string]$Description,
        [Parameter()]
        [string]$Tag,
        [Parameter()]
        [string]$SourceZone,
        [Parameter()]
        [string]$SourceAddress,
        [Parameter()]
        [string]$SourceUser,
        [Parameter()]
        [string]$HipProfile,
        [Parameter()]
        [string]$DestinationZone,
        [Parameter()]
        [string]$DestinationAddress,
        [Parameter()]
        [string]$Application,
        [Parameter()]
        [string]$Service,
        [Parameter()]
        [string]$UrlCategory,
        [Parameter()]
        [ValidateSet("yes","no")]
        [string]$SourceNegate,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$DestinationNegate,
        [Parameter()]
        [ValidateSet("allow","deny")] 
        [string]$Action,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$LogStart,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$LogEnd,
        [Parameter()]
        [string]$LogForward,
        [Parameter()]
        [string]$Schedule,
        [Parameter()]
        [ValidateSet("yes","no")]
        [string]$Disabled,
        [Parameter()]
        [string]$ProfileGroup,
        [Parameter()]
        [string]$ProfileVirus,
        [Parameter()]
        [string]$ProfileVuln,
        [Parameter()]
        [string]$ProfileSpy,
        [Parameter()]
        [string]$ProfileUrl,
        [Parameter()]
        [string]$ProfileFile,
        [Parameter()]
        [string]$ProfileData,
        [Parameter()]
        [ValidateSet("none","af11","af12","af13","af21","af22","af23","af31","af32","af33","af41","af42","af43","cs0","cs1","cs2","cs3","cs4","cs5","cs6","cs7","ef")] 
        [string]$QosDscp,
        [Parameter()]
        [ValidateSet("none","cs0","cs1","cs2","cs3","cs4","cs5","cs6","cs7")] 
        [string]$QosPrecedence,
        [Parameter()]
        [ValidateSet("yes","no")] 
        [string]$DisableSri
    )

    BEGIN {
        $WebClient = New-Object System.Net.WebClient
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

        function EditProperty ($parameter,$element,$xpath) {
            if ($parameter) {
                if ($parameter -eq "none") { $action = "delete" } `
                    else                   { $action = "edit" }
                $Response = Send-PaApiQuery -Config $action -XPath $xpath -Element $element -Member $parameter
                if ($Response.response.status -eq "success") {
                    return "$element`: success"
                } else {
                    throw $Response.response.msg.line
                }
            }
        }
        Function Process-Query ( [String]$PaConnectionString ) {
            $xpath = "/config/devices/entry/vsys/entry/rulebase/security/rules/entry[@name='$Name']"
            
            if ($Rename) {
                $Response = Send-PaApiQuery -Config rename -XPath $xpath -NewName $Rename -PaConnection $PaConnectionString
                if ($Response.response.status -eq "success") {
                    return "Rename success"
                } else {
                    throw $Response.response.msg.line
                }
            }

            EditProperty $Description "description" $xpath
            EditProperty $SourceNegate "negate-source" $xpath
            EditProperty $DestinationNegate "negate-destination" $xpath
            EditProperty $Action "action" $xpath
            EditProperty $LogStart "log-start" $xpath
            EditProperty $LogEnd "log-end" $xpath
            EditProperty $LogForward "log-setting" $xpath
            EditProperty $Schedule "schedule" $xpath
            EditProperty $Disabled "disabled" $xpath
            EditProperty $QosDscp "ip-dscp" "$xpath/qos/marking"
            EditProperty $QosPrecedence "ip-precedence" "$xpath/qos/marking"
            EditProperty $DisableSri "disable-server-response-inspection" "$xpath/option"
            EditProperty $SourceAddress "source" $xpath
            EditProperty $SourceZone "from" $xpath
            EditProperty $Tag "tag" $xpath
            EditProperty $SourceUser "source-user" $xpath
            EditProperty $HipProfile "hip-profiles" $xpath
            EditProperty $DestinationZone "to" $xpath
            EditProperty $DestinationAddress "destination" $xpath
            EditProperty $Application "application" $xpath
            EditProperty $Service "service" $xpath
            EditProperty $UrlCategory "category" $xpath
            EditProperty $HipProfile "hip-profiles" $xpath
            EditProperty $ProfileGroup "group" "$xpath/profile-setting"
            EditProperty $ProfileVirus "virus" "$xpath/profile-setting/profiles"
            EditProperty $ProfileVuln "vulnerability" "$xpath/profile-setting/profiles"
            EditProperty $ProfileSpy "spyware" "$xpath/profile-setting/profiles"
            EditProperty $ProfileUrl "url-filtering" "$xpath/profile-setting/profiles"
            EditProperty $ProfileFile "file-blocking" "$xpath/profile-setting/profiles"
            EditProperty $ProfileData "data-filtering" "$xpath/profile-setting/profiles"
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $Script:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
        
    }
}