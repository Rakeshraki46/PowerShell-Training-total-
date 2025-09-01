# Payslip HTTP Server with PowerShell (Improved)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:8095/")
$listener.Start()
Write-Host "✅ Payslip server running at http://127.0.0.1:8095/"

try {
    $csvPath = "C:\Git\PowerShell\PAYSLIP\PaySlip.csv"
    if (-Not (Test-Path $csvPath)) {
        throw "❌ ERROR: '$csvPath' not found."
    }
    $employeeData = Import-Csv $csvPath
    Write-Host "✅ Loaded $csvPath with $($employeeData.Count) records"
} catch {
    Write-Host $_.Exception.Message
    exit
}

$baseDir = "C:\Git\PowerShell"

while ($listener.IsListening) {
    $context = $null
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $url = [uri]::UnescapeDataString($request.Url.AbsolutePath)

        Write-Host "➡️ Request for: $url"

        # Handle favicon
        if ($url -eq "/favicon.ico") {
            $response.StatusCode = 204
            $response.Close()
            continue
        }

        # API login endpoint
        if ($url -eq "/api/login" -and $request.HttpMethod -eq "POST") {
            if ($request.ContentLength64 -eq 0) {
                $response.StatusCode = 400
                $response.Close()
                Write-Host "❌ No data received in POST"
                continue
            }

            try {
                $reader = New-Object System.IO.StreamReader($request.InputStream)
                $bodyRaw = $reader.ReadToEnd()
                Write-Host "🔽 Raw POST Body: $bodyRaw"

                $body = $bodyRaw | ConvertFrom-Json
            } catch {
                Write-Host "❌ Failed to parse JSON body: $($_.Exception.Message)"
                $response.StatusCode = 400
                $response.Close()
                continue
            }

            $emp = $employeeData | Where-Object { $_.EmployeeID -eq $body.EmployeeID }
            if ($emp) {
                $response.ContentType = 'application/json'
                $output = $emp | ConvertTo-Json
                [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($output)
                Write-Host "✅ Employee found: $($emp.EmployeeID)"
            } else {
                $response.StatusCode = 404
                [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Employee not found"}')
                Write-Host "❌ Employee not found"
            }
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        }

        # Serve static files
        elseif ($url -match '^/public/') {
            $localPath = $url.Replace('/', '\\').TrimStart('\\')
            $filePath = Join-Path $baseDir $localPath
            Write-Host "📄 Looking for file: $filePath"

            if (Test-Path $filePath) {
                $buffer = [System.IO.File]::ReadAllBytes($filePath)
                switch ([System.IO.Path]::GetExtension($filePath)) {
                    '.html' { $response.ContentType = 'text/html' }
                    '.css'  { $response.ContentType = 'text/css' }
                    '.js'   { $response.ContentType = 'application/javascript' }
                    default { $response.ContentType = 'application/octet-stream' }
                }
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "✅ Served file: $filePath"
            } else {
                $response.StatusCode = 404
                [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "❌ File not found: $filePath"
            }
            $response.OutputStream.Close()
        }

        # Default: Serve index.html
        else {
            $redirectPath = "/public/index.html"
            $filePath = Join-Path $baseDir ($redirectPath.Replace('/', '\\').TrimStart('\\'))
            Write-Host "🔍 Trying to redirect to $redirectPath (Full path: $filePath)"

            if (Test-Path $filePath) {
                $buffer = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = 'text/html'
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "🔁 Served index.html from redirect"
            } else {
                $response.StatusCode = 503
                [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes("503 Service Unavailable - index.html not found")
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "🚫 index.html not found, cannot serve or redirect"
            }
            $response.OutputStream.Close()
        }
    } catch {
        Write-Host "🔥 ERROR: $($_.Exception.Message)"
        if ($context -and $context.Response) {
            try {
                $context.Response.StatusCode = 500
                [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes("500 Internal Server Error")
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            } catch {}
        }
    }
}
