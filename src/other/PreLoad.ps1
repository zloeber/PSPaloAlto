# Private Module Variables

# Array of our connected palo altos (well firewalls which we were able to generate a connection string for)
$PaConnectionArray = @()

# Stores the immediate URL that was used in the last XML call to the device
$LastURL = ''

# Stores the last result of an XML query to th device
$LastRepsponse = ''

# Used to track if SSL work around configuration is in place
$script:_IgnoreSSL = $false

#
$script:modCertCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback