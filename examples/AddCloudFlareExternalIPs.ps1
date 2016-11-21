# Add Cloudflare external IPs from https://www.cloudflare.com/ips/ as address objects to your firewall
# Additionally this will set the tag on each object to 'CloudflareExternalIP' for use in a dynamic address group later
$cred = Get-Credential
Connect-PA -Address 192.168.1.1 -Cred $cred

$IPs = @'
103.21.244.0/22
103.22.200.0/22
103.31.4.0/22
104.16.0.0/12
108.162.192.0/18
131.0.72.0/22
141.101.64.0/18
162.158.0.0/15
172.64.0.0/13
173.245.48.0/20
188.114.96.0/20
190.93.240.0/20
197.234.240.0/22
198.41.128.0/17
199.27.128.0/21
'@

$Count = 1
$IPs.Split("`r`n") | Foreach {
    $IP,$Mask = $_ -split '/'
    $Name = 'net_ext_' + $IP + '_' + $Mask
    Set-PaAddressObject -Name $Name -IPNetmask $_ -Description "Cloudflare External $Count"
    Set-PaAddressObjectTag -Name $Name -Tags 'CloudflareExternalIP'
    $Count++
}