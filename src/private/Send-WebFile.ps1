# This was pulled from within some other functions and isn't actually in use from what I can tell.
function Send-WebFile ($url) {
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($data)

    [System.Net.HttpWebRequest] $webRequest = [System.Net.WebRequest]::Create($url)

    $webRequest.Method = "POST"
    $webRequest.ContentType = "text/html"
    $webRequest.ContentLength = $buffer.Length;

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($buffer, 0, $buffer.Length)
    $requestStream.Flush()
    $requestStream.Close()


    [System.Net.HttpWebResponse] $webResponse = $webRequest.GetResponse()
    $streamReader = New-Object System.IO.StreamReader($webResponse.GetResponseStream())
    $result = $streamReader.ReadToEnd()
    return $result
}