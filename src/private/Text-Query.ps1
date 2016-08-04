function Text-Query ( $entry, [String]$PaProp ) {
    if ($entry."$PaProp"."#text") {
        return $entry."$PaProp"."#text"
    }
    else {
        return  $entry."$PaProp"
    }
}