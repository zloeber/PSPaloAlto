function Send-PaApiQuery {
    <#
    .SYNOPSIS
    Formulate and send an api query to a PA firewall.
    .DESCRIPTION
    Formulate and send an api query to a PA firewall.
    .PARAMETER Config
    Type of configuration query to send: show, get, set, edit, delete, rename, clone, or move.
    .PARAMETER XPath
    XPath to query
    .PARAMETER Element
    Element to query
    .PARAMETER Member
    Member to query
    .PARAMETER NewName
    NewName
    .PARAMETER CloneFrom
    CloneFrom
    .PARAMETER MoveWhere
    MoveWhere
    .PARAMETER MoveDestination
    MoveDestination
    .PARAMETER Op
    Operator to use
    .PARAMETER Report
    Report
    .PARAMETER ReportName
    ReportName
    .PARAMETER Rows
    Rows
    .PARAMETER Period
    Period
    .PARAMETER StartTime
    StartTime
    .PARAMETER EndTime
    EndTime
    .PARAMETER Export
    Export
    .PARAMETER From
    From
    .PARAMETER To
    To
    .PARAMETER DlpPassword
    DlpPassword
    .PARAMETER CertificateName
    CertificateName
    .PARAMETER CertificateFormat
    CertificateFormat
    .PARAMETER ExportPassPhrase
    ExportPassPhrase
    .PARAMETER TsAction
    TsAction
    .PARAMETER Job
    Job
    .PARAMETER ExportFile
    ExportFile
    .PARAMETER Import
    Import
    .PARAMETER ImportFile
    ImportFile
    .PARAMETER ImportCertificateName
    ImportCertificateName
    .PARAMETER ImportCertificateFormat
    ImportCertificateFormat
    .PARAMETER ImportPassphrase
    ImportPassphrase
    .PARAMETER ImportProfile
    ImportProfile
    .PARAMETER ImportWhere
    ImportWhere
    .PARAMETER Log
    Log
    .PARAMETER LogQuery
    LogQuery
    .PARAMETER NumberLogs
    NumberLogs
    .PARAMETER SkipLogs
    SkipLogs
    .PARAMETER LogAction
    LogAction
    .PARAMETER LogJob
    LogJob
    .PARAMETER UserId
    UserId
    .PARAMETER Commit
    Commit
    .PARAMETER Force
    Force
    .PARAMETER Partial
    Partial
    .PARAMETER PaConnection
    Specificies the Palo Alto connection string with address and apikey. If ommitted, current connections will be used
    .EXAMPLE
    TBD
    #>
    Param (
        #############################CONFIG#############################

        [Parameter(ParameterSetName = "config", Mandatory = $True, Position = 0)]
        [ValidateSet("show", "get", "set", "edit", "delete", "rename", "clone", "move")]
        [String]$Config,

        [Parameter(ParameterSetName = "config", Mandatory = $True)]
        [ValidatePattern("\/config\/.*")]
        [String]$XPath,

        [Parameter(ParameterSetName = "config")]
        [alias('e')]
        [String]$Element,

        [Parameter(ParameterSetName = "config")]
        [alias('m')]
        [String]$Member,

        [Parameter(ParameterSetName = "config")]
        [alias('nn')]
        [String]$NewName,

        #========================CLONE=========================#

        [Parameter(ParameterSetName = "config")]
        [alias('cf')]
        [String]$CloneFrom,

        #=========================MOVE=========================#

        [Parameter(ParameterSetName = "config")]
        [alias('mw')]
        [ValidateSet("after", "before", "top", "bottom")]
        [String]$MoveWhere,

        [Parameter(ParameterSetName = "config")]
        [alias('dst')]
        [String]$MoveDestination,

        ###########################OPERATIONAL##########################

        [Parameter(ParameterSetName = "op", Mandatory = $True, Position = 0)]
        [ValidatePattern("<\w+>.*<\/\w+>")]
        [String]$Op,

        #############################REPORT#############################

        [Parameter(ParameterSetName = "report", Mandatory = $True, Position = 0)]
        [ValidateSet("dynamic", "predefined")]
        #No Custom Reports supported yet, should probably make a seperate cmdlet for it.
        [String]$Report,

        [Parameter(ParameterSetName = "report")]
        [alias('rn')]
        [String]$ReportName,

        [Parameter(ParameterSetName = "report")]
        [alias('r')]
        [Decimal]$Rows,

        [Parameter(ParameterSetName = "report")]
        [alias('p')]
        [ValidateSet("last-60-seconds", "last-15-minutes", "last-hour", "last-12-hrs", "last-24-hrs", "last-calendar-day", "last-7-days", "last-7-calendar-days", "last-calendar-week", "last-30-days")]
        [String]$Period,

        [Parameter(ParameterSetName = "report")]
        [alias('start')]
        [ValidatePattern("\d{4}\/\d{2}\/\d{2}\+\d{2}:\d{2}:\d{2}")]
        [String]$StartTime,

        [Parameter(ParameterSetName = "report")]
        [alias('end')]
        [ValidatePattern("\d{4}\/\d{2}\/\d{2}\+\d{2}:\d{2}:\d{2}")]
        [String]$EndTime,

        #############################EXPORT#############################

        [Parameter(ParameterSetName = "export", Mandatory = $True, Position = 0)]
        [ValidateSet("application-pcap", "threat-pcap", "filter-pcap", "filters-pcap", "configuration", "certificate", "high-availability-key", "key-pair", "application-block-page", "captive-portal-text", "file-block-continue-page", "file-block-page", "global-protect-portal-custom-help-page", "global-protect-portal-custom-login-page", "global-protect-portal-custom-welcome-page", "ssl-cert-status-page", "ssl-optout-text", "url-block-page", "url-coach-text", "virus-block-page", "tech-support", "device-state")]
        [String]$Export,

        [Parameter(ParameterSetName = "export")]
        [alias('f')]
        [String]$From,

        [Parameter(ParameterSetName = "export")]
        [alias('t')]
        [String]$To,

        #=========================DLP=========================#

        [Parameter(ParameterSetName = "export")]
        [alias('dp')]
        [String]$DlpPassword,

        #=====================CERTIFICATE=====================#

        [Parameter(ParameterSetName = "export")]
        [alias('ecn')]
        [String]$CertificateName,

        [Parameter(ParameterSetName = "export")]
        [alias('ecf')]
        [ValidateSet("pkcs12", "pem")]
        [String]$CertificateFormat,

        [Parameter(ParameterSetName = "export")]
        [alias('epp')]
        [String]$ExportPassPhrase,

        #=====================TECH SUPPORT====================#

        [Parameter(ParameterSetName = "export")]
        [alias('ta')]
        [ValidateSet("status", "get", "finish")]
        [String]$TsAction,

        [Parameter(ParameterSetName = "export")]
        [alias('j')]
        [Decimal]$Job,

        [Parameter(ParameterSetName = "export", Mandatory = $True)]
        [alias('ef')]
        [String]$ExportFile,


        #############################IMPORT#############################

        [Parameter(ParameterSetName = "import", Mandatory = $True, Position = 0)]
        [ValidateSet("software", "anti-virus", "content", "url-database", "signed-url-database", "license", "configuration", "certificate", "high-availability-key", "key-pair", "application-block-page", "captive-portal-text", "file-block-continue-page", "file-block-page", "global-protect-portal-custom-help-page", "global-protect-portal-custom-login-page", "global-protect-portal-custom-welcome-page", "ssl-cert-status-page", "ssl-optout-text", "url-block-page", "url-coach-text", "virus-block-page", "global-protect-client", "custom-logo")]
        [String]$Import,

        [Parameter(ParameterSetName = "import", Mandatory = $True, Position = 1)]
        [String]$ImportFile,

        #=====================CERTIFICATE=====================#

        [Parameter(ParameterSetName = "import")]
        [alias('icn')]
        [String]$ImportCertificateName,

        [Parameter(ParameterSetName = "import")]
        [alias('icf')]
        [ValidateSet("pkcs12", "pem")]
        [String]$ImportCertificateFormat,

        [Parameter(ParameterSetName = "import")]
        [alias('ipp')]
        [String]$ImportPassPhrase,

        #====================RESPONSE PAGES====================#

        [Parameter(ParameterSetName = "import")]
        [alias('ip')]
        [String]$ImportProfile,

        #=====================CUSTOM LOGO======================#

        [Parameter(ParameterSetName = "import")]
        [alias('wh')]
        [ValidateSet("login-screen", "main-ui", "pdf-report-footer", "pdf-report-header")]
        [String]$ImportWhere,

        ##############################LOGS##############################

        [Parameter(ParameterSetName = "log", Mandatory = $True, Position = 0)]
        [ValidateSet("traffic", "threat", "config", "system", "hip-match", "get", "finish")]
        [String]$Log,

        [Parameter(ParameterSetName = "log")]
        [alias('q')]
        [String]$LogQuery,

        [Parameter(ParameterSetName = "log")]
        [alias('nl')]
        [ValidateRange(1, 5000)]
        [Decimal]$NumberLogs,

        [Parameter(ParameterSetName = "log")]
        [alias('sl')]
        [String]$SkipLogs,

        [Parameter(ParameterSetName = "log")]
        [alias('la')]
        [ValidateSet("get", "finish")]
        [String]$LogAction,

        [Parameter(ParameterSetName = "log")]
        [alias('lj')]
        [Decimal]$LogJob,

        #############################USER-ID############################

        [Parameter(ParameterSetName = "userid", Mandatory = $True, Position = 0)]
        [ValidateSet("get", "set")]
        [String]$UserId,

        #############################COMMIT#############################

        [Parameter(ParameterSetName = "commit", Mandatory = $True, Position = 0)]
        [Switch]$Commit,

        [Parameter(ParameterSetName = "commit")]
        [Switch]$Force,

        [Parameter(ParameterSetName = "commit")]
        [alias('part')]
        [String]$Partial,

        ############################CONNECTION##########################

        [Parameter()]
        [alias('pc')]
        [String]$PaConnection
    )

    Begin {
        # Pull in all the caller verbose,debug,info,warn and other preferences
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand

        if ([string]::IsNullOrEmpty($PaConnection.ConnectionString)) {
            if (($script:PaConnectionArray).Count -gt 0) {
                Write-Verbose "$($FunctionName): Using existing connections to $(($script:PaConnectionArray).Count) Firewalls."
                $PaConnections = @($script:PaConnectionArray)
            }
            else {
                throw "$($FunctionName): Connection has not been established with any firewall. Create a new connection with Connect-PA first."
            }
        }
        else {
            $PaConnections = @($PAConnection)
        }
    }

    Process {
        foreach ($Connection in $PaConnections) {
            Write-Verbose "$($FunctionName): Processing against connection to $($Connection.Address)"
            $url = $Connection.ConnectionString
            switch ($PSCmdlet.ParameterSetName) {
                'Config' {
                    $ReturnType = "String"
                    $url += "&type=config"
                    $url += "&action=$Config"
                    $url += "&xpath=$xpath"
                    if (($Config -eq "set") -or ($Config -eq "edit") -or ($Config -eq "delete")) {
                        #if ($Element) { $url += "/$Element" }
                        $Members = ''
                        if ($Member) {
                            $Member = $Member.replace(" ", '%20')
                            #                        if ($Member -match ",") {

                            foreach ($Value in $Member.split(',')) {
                                if ($Value) { $Members += "<member>$Value</member>" }
                            }
                            $Member = $Members
                        }
                        if ($Element) {
                            $url += "&element=<$element>$Member</$element>"
                        }
                        elseif ($Member -ne '') {
                            $url += "&element=$Member"
                        }
                    }
                    elseif ($Config -eq "rename") {
                        $url += "&newname=$NewName"
                    }
                    elseif ($Config -eq "clone") {
                        $url += "/"
                        $url += "&from=$xpath/$CloneFrom"
                        $url += "&newname=$NewName"
                        return "Times out ungracefully as of 11/20/12 on 5.0.0"
                    }
                    elseif ($Config -eq "move") {
                        $url += "&where=$MoveWhere"
                        if ($MoveDestination) {
                            $url += "&dst=$MoveDestination"
                        }
                    }

                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
                'Op' {
                    $ReturnType = "String"
                    $url += "&type=op"
                    $url += "&cmd=$Op"

                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
                'Report' {
                    $ReturnType = "String"
                    $url += "&type=report"
                    $url += "&reporttype=$Report"
                    if ($ReportName) { $url += "&reportname=$ReportName" }
                    if ($Rows) { $url += "&topn=$Rows" }
                    if ($Period) {
                        $url += "&period=$Period"
                    }
                    elseif ($StartTime) {
                        $url += "&starttime=$StartTime"
                        if ($EndTime) { $url += "&starttime=$EndTime" }
                    }
                    Get-WebRequestAsXML $url
                }
                'Export' {
                    if (($export -eq "filters-pcap") -or ($export -eq "filter-pcap")) {
                        return "Times out ungracefully as of 11/20/12 on 5.0.0"
                    }
                    $url += "&type=export"
                    $url += "&category=$Export"
                    if ($From) { $url += "&from=$From" }
                    if ($To) { $url += "&to=$To" }
                    if ($DlpPassword) { $url += "dlp-password=$DlpPassword" }
                    if ($CertificateName) {
                        $url += "&certificate-name=$CertificateName"
                        $url += "&include-key=no"
                    }
                    if ($CertificateFormat) { $url += "&format=$CertificateFormat" }
                    if ($ExportPassPhrase) {
                        $url += "&include-key=yes"
                        $url += "&passphrase=$ExportPassPhrase"
                    }
                    if ($TsAction) { $url += "&action=$TsAction" }
                    if ($Job) { $url += "&job-id=$Job" }
                    try {
                        Get-WebRequestAsXML $url $ExportFile
                        Write-Output "$($FunctionName): File downloaded to $ExportFile"
                    }
                    catch {
                        throw 'Unable to export file!'
                    }
                }
                'Import' {
                    $url += "&type=import"
                    $url += "&category=$Import"
                    if ($ImportCertificateName) {
                        $url += "&certificate-name=$ImportCertificateName"
                        $url += "&format=$ImportCertificateFormat"
                        $url += "&passphrase=$ImportPassPhrase"
                    }
                    if ($ImportProfile) { $url += "&profile=$ImportProfile" }
                    if ($ImportWhere) { $url += "&where=$ImportWhere" }
                    $script:LastURL = $url

                    #return Send-WebFile $url $ImportFile
                    return "Currently non-functional, not sure how to do this with webclient"
                }
                'Log' {
                    $url += "&type=log"
                    if ($Log -eq "get") {
                        $url += "&action=$log"
                        $url += "&job-id=$LogJob"
                    }
                    else {
                        $url += "&log-type=$Log"
                    }


                    if ($LogQuery) {
                        $Query = [System.Web.HttpUtility]::UrlEncode($LogQuery)
                        $url += "&query=$Query"
                    }
                    if ($NumberLogs) { $url += "&nlogs=$NumberLogs" }
                    if ($SkipLogs) { $url += "&skip=$SkipLogs" }

                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url

                    $script:LastResponse
                }
                'UserID' {
                    $url += "&type=user-id"
                    $url += "&action=$UserId"
                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
                'Commit' {
                    $url += "&type=commit"
                    $url += "&cmd=<commit></commit>"
                    $script:LastURL = $url
                    $script:LastResponse = Get-WebRequestAsXML $url
                    $script:LastResponse
                }
            }
        }
    }
}