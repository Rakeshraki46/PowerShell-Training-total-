$uri = "https://75fca097-b2b6-4156-9efa-d1e920359c6f.webhook.eus.azure-automation.net/webhooks?token=brJ%2b5jgO6O2hZJcYguf7IJafJ%2bSOHJnUbYYGqYKR84k%3d"
$headerMessage = @{ message = "startedByRocky"}
$Names  = @(
            @{ Name="Hawaii"},
            @{ Name="Seattle"},
            @{ Name="Florida"}
        )

$body = ConvertTo-Json -InputObject $Names
$response = Invoke-WebRequest -Method Post -Uri $uri -Header $headerMessage -Body $body -UseBasicParsing
$response

#