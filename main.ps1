
 
function loadHeader ([ref]$stream) {
      
    $chunkString = Read-Bytes -length 4 -Stream $stream -as "string"
    $ChunkSize = Read-Bytes -length 4 -Stream $Stream -as "int32"

    if ($chunkString -eq "RIFF") {
        $format = Read-Bytes -length 4 -Stream $Stream -as "string"
        return @{
            chunkString = $chunkString
            fileSize    = $ChunkSize
            format      = $format
        }
    }
}

function loadFMT ([ref]$stream) {

    $chunkString = Read-Bytes -length 4 -Stream $stream -as "string"
    $ChunkSize = Read-Bytes -length 4 -Stream $Stream -as "int32"

    if ($chunkString -eq "fmt ") {
        return @{
            ChunkSize     = $ChunkSize
            audioFormat   = Read-Bytes -length 2 -Stream $stream -as "int16"
            numChannels   = Read-Bytes -length 2 -Stream $stream -as "int16"
            sampleRate    = Read-Bytes -length 4 -Stream $stream -as "int32"
            byteRate      = Read-Bytes -length 4 -Stream $stream -as "int32"
            blockAlign    = Read-Bytes -length 2 -Stream $stream -as "int16"
            bitsPerSample = Read-Bytes -length 2 -Stream $stream -as "int16"
        }
    }
}
function loadData ([ref]$stream, $fmt) {

    $chunkString = Read-Bytes -length 4 -Stream $stream -as "string"
    $ChunkSize = Read-Bytes -length 4 -Stream $Stream -as "int32"

    if ($chunkString -eq "data") { 
        $data = $fmt
        $channelLength = $ChunkSize / ($data.numChannels * $data.bitsPerSample / 8)
        $stride = $data.blockAlign / $data.numChannels

        if ($stride -eq 2) { $type = "int16" }
        else { $type = "int32" }

        $channels = [Int16[][]]::new($data.numChannels, $channelLength) 
        for ($i = 0; $i -lt $channelLength; $i++) {
            for ($j = 0; $j -lt $data.numChannels ; $j++) {
                $channels[$j][$i] = Read-Bytes -length $stride -stream $stream -as $type
               
                if ($i % 1000 -eq 0) { Write-Host "Read Byte $($channels[$j][$i]) from channel $j. $i of $channelLength" }
                
            }
        }
        return $channels
    }
}

function Read-Bytes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $length,
        [ref]$Stream,
        [switch]$BigEndian,
        $as
    )
    $Data = [System.Byte[]]::new($length)
    $null = $Stream.Value.Read($Data, 0, $length)

    $res = switch ($as) {
        "int16" { [BitConverter]::ToInt16($Data, 0) }
        "int32" { [BitConverter]::ToInt32($Data, 0) }
        "string" { [char[]]$Data -join '' }
        Default { $Data }
    }
    return $res
}


$file = (Get-ChildItem ./money_machine_nometa.wav).FullName
$Stream = [System.IO.File]::Open($file, [System.IO.FileMode]::Open)

$header = loadHeader([ref]$Stream)
$fmt = loadFMT([ref]$Stream)
$data = loadData -stream ([ref]$Stream) -fmt $fmt
# Close the FileStream
$Stream.Close()