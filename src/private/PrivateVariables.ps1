# Private Module Variables

# Array of our connected palo altos (well firewalls which we were able to generate a connection string for)
$PaConnectionArray = @()

# Stores the immediate URL that was used in the last XML call to the device
$LastURL = ''

# Stores the last result of an XML query to th device
$LastRepsponse = ''

#$test = New-Object -TypeName PSObject -Property @{
#    'ConnectionString' = $null
#    'ApiKey' = $null
#    'Address' = $null
#}
