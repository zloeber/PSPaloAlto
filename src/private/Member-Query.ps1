function Member-Query ( $entry, [String]$PaProp ) {
    if ($entry."$PaProp".member."#text") {
        return $entry."$PaProp".member."#text"
    } 
    else {
        return  $entry."$PaProp".member
    }
}