#$result = dsc config get --file .\ps-script.dsc.yaml
#$result = dsc config test --file .\ps-script.dsc.yaml

Write-Host "DSC for certificate "


$result = dsc config set --file .\ps-script-certificate.dsc.yaml --output-format pretty-json | ConvertFrom-Json -Depth 20

$thumbprint = if ($result.results.result.afterState.output -is [System.Array]) {
    $result.results.result.afterState.output[0].Thumbprint
} else {
    $result.results.result.afterState.output.Thumbprint
}

if (-not $thumbprint) {
    throw "Thumbprint was not found in DSC output."
}


Write-Host "DSC for certificate Thumbprint: " $thumbprint

$inlineParams = @{
    parameters = @{
        certThumbprint = $thumbprint
    }
} | ConvertTo-Json

# dsc config --parameters $inlineParams get --file .\winrm.dsc.yaml
# dsc config --parameters $inlineParams test --file .\winrm.dsc.yaml

Write-Host "DSC - winrm HTTPS setup"

dsc config --parameters $inlineParams set --file .\winrm.dsc.yaml