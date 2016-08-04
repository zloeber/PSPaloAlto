function Restart-PaSystem {
    <#
	.SYNOPSIS
		Restarts PA and watches initial autocommit job for completion.
	.DESCRIPTION
		
	.EXAMPLE
        EXAMPLES!
	.EXAMPLE
		EXAMPLES!
	.PARAMETER PaConnectionString
		Specificies the Palo Alto connection string with address and apikey. If ommitted, $global:PaConnectionArray will be used
	#>

    Param (
        [Parameter(Mandatory=$False)]
        [alias('pc')]
        [String]$PaConnection,

        [Parameter(Mandatory=$False)]
        [alias('dw')]
        [String]$DontWait,
        
        [Parameter(Mandatory=$False)]
        [alias('i')]
        [Decimal]$Id,
        
        [Parameter(Mandatory=$False)]
        [alias('p')]
        [Decimal]$Parentid
    )

    BEGIN {
        Function Process-Query ( [String]$PaConnectionString ) {
            #Configure progress bar for waiting for a response
            $WaitJobParams = @{Activity = "Sending Reboot Commnad"}
            if ($Id)          { $WaitJobParams.Add("Id",$id) }
            if ($ParentId)    { $WaitJobParams.Add("ParentId",$Parentid) }

            #Reboot the system
            $xpath = "<request><restart><system></system></restart></request>"
            $Reboot = Send-PaApiQuery -Op $xpath
            
            #If desired, down't wait for the system to come back up
            if ($DontWait) { return $Reboot }
            
            #Wait for system to go down (so we don't get a false positive and think it's already back up)
            for ($w = 0;$w -le 14;$w++) {
                $Caption = "Sleeping $(15 - $w)"
                $WaitJobParams.Set_Item("Activity",$Caption)
                Write-Progress @WaitJobParams
                sleep 1
            }

            #Update Progress Bar
            $WaitJobParams.Set_Item("Activity","Trying to connect")

            #Set our test condition to false
            $RebootTest = $false

            #Configure progress bar for waiting for job 1 to complete after reboot
            $WatchJobParams = @{ job = 1
                                 caption = "Waiting for reboot" }
            if ($Id)           { $WatchJobParams.Add("Id",$id) }
            if ($ParentId)     { $WatchJobParams.Add("ParentId",$Parentid) }

            #Attempt counter
            $a = 1

            #Loop until $RebootTest is true
            while (!($RebootTest)) {
                try {
                    #attempt to connect
                    $WaitJobParams.Set_Item("Activity","Attempting to connect")
                    Write-Progress @WaitJobParams
                    $RebootJob = Watch-PaJob @WatchJobParams
                    if ($RebootJob.response) { $RebootTest = $true }
                } catch {
                    #if exception from try block (thrown by $RebootJob), wait 15 seconds, updates progress
                    for ($w = 0;$w -le 14;$w++) {
                        $Caption = "Attempt $a`: Unable to connect, Trying again in $(15 - $w)"
                        $WaitJobParams.Set_Item("Activity",$Caption)
                        Write-Progress @WaitJobParams
                        sleep 1
                        #increment attempt counter
                    }
                    $a++
                    $RebootTest = $false
                }
                
            }
            return $RebootJob
        }
    }

    PROCESS {
        if ($PaConnection) {
            Process-Query $PaConnection
        } else {
            if (Test-PaConnection) {
                foreach ($Connection in $Global:PaConnectionArray) {
                    Process-Query $Connection.ConnectionString
                }
            } else {
                Throw "No Connections"
            }
        }
    }
}