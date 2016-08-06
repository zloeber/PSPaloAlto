# Update these to suit your PowerShell module build. These variables get dot sourced into 
# the build at every run. The path root of the locations are assumed to be at the root of the 
# PowerShell module project directory.

# NOTE: The first variables are the most important. All the other are a matter of preference

# The module we are building
$ModuleToBuild = 'PSPaloAlto'

# Project website (used for external help cab file definition) 
$ModuleWebsite = 'https://github.com/zloeber/PSPaloAlto'

# Some tags that describe your module. 
# Example: @('Code Formatting', 'Module Creation', 'Build Scripts')
$ModuleTags = @('Palo_Alto','Firewall','API','Security')

# Module Author
$ModuleAuthor = 'Zachary Loeber'

# Module Author
$ModuleDescription = 'Several functions for interfacing with the XLM interface of Palo Alto firewalls'

# Options - These affect how your eventual build will be run.
$OptionFormatCode = $false
$OptionAnalyzeCode = $false
$OptionCombineFiles = $true

# PlatyPS has been the cause of most of my build failures. This can help you isolate which functrion's CBH is causing you grief.
$OptionRunPlatyPSVerbose = $false

# Additional paths in the source module which should be copied over to the final build release
# Example: @('.\libs','.\data')
$AdditionalModulePaths = @()

# Please leave anything below this line alone
$ModuleToBuild, $ModuleWebsite, $ModuleAuthor, $ModuleDescription | Foreach {
    if ([string]::IsNullOrEmpty($_)) {
        Write-Error 'You must first define all of the environment variables in .buildenvironment.ps1!'
    }
    if ($ModuleTags.Count -eq 0) {
        Write-Error 'You must first assign a few tags to your module in .buildenvironment.ps1!'
    }
}