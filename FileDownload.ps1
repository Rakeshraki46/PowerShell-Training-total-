# Google Cloud Storage URL (MPN-allowed)
$url = "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"

# Download folder (customize as needed)
$downloadFolder = "C:\Downloads\TestFiles"
if (-not (Test-Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}

# Download the file 10 times with unique names
for ($i = 1; $i -le 10; $i++) {
    $outFile = Join-Path $downloadFolder "BigBuckBunny-$i-$(Get-Random).mp4"
    Write-Host "Downloading"
}