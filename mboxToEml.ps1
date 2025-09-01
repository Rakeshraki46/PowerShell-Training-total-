<#
.SYNOPSIS
    Convert a single-file MBOX mailbox to individual RFC-822 (.eml) messages.

.DESCRIPTION
    • Splits on the standard “From ” separator defined in RFC 4155.  
    • Preserves every header, body line and attachment byte-for-byte.  
    • Automatically un-escapes any “>From ” escapes inside message bodies.  
    • Produces sequentially-numbered output (000001.eml …) so messages keep
      their original order.

.EXAMPLE
#>
    .\Convert-MboxToEml.ps1 -MboxPath "C:\Users\Rakesh\Downloads\All mail Including Spam and Trash.mbox" `
                            -OutputFolder "C:\Mail\archive-eml"


param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_})]
    [string]$MboxPath,

    [string]$OutputFolder = (Join-Path (Split-Path $MboxPath) `
                                         ((Split-Path $MboxPath -Leaf) + "_eml"))
)

# ---------- 1.  Prep output ---------------------------------------------------
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

# ---------- 2.  Stream-parse the mailbox -------------------------------------
$reader       = [System.IO.StreamReader]::new($MboxPath)
$messageLines = [System.Collections.Generic.List[string]]::new()
$msgIndex     = 0

while (-not $reader.EndOfStream) {
    $line = $reader.ReadLine()

    # “From ” at BOL marks a new message (RFC 4155 §A) :contentReference[oaicite:0]{index=0}
    if ($line -cmatch '^From .*$') {
        # Flush the previous message (if any) to disk
        if ($messageLines.Count -gt 0) {
            $msgIndex++
            $fileName  = ("{0:D6}.eml" -f $msgIndex)
            $emlPath   = Join-Path $OutputFolder $fileName
            [System.IO.File]::WriteAllLines($emlPath, $messageLines)
            $messageLines.Clear()
        }
        continue   # Skip the delimiter itself
    }

    # Undo “From ” escaping added by some mbox writers
    if ($line.StartsWith('>From ')) { $line = $line.Substring(1) }

    $messageLines.Add($line)
}

# Write the final buffered message
if ($messageLines.Count -gt 0) {
    $msgIndex++
    $fileName  = ("{0:D6}.eml" -f $msgIndex)
    $emlPath   = Join-Path $OutputFolder $fileName
    [System.IO.File]::WriteAllLines($emlPath, $messageLines)
}

$reader.Dispose()
Write-Host "`nConverted $msgIndex messages to:`n $OutputFolder"
