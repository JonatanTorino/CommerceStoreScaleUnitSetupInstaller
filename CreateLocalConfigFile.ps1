Import-Module .\Support\SupportFunctions.ps1
CurrentFileName $MyInvocation.MyCommand.Name

# Crear archivo
$hostname = $env:COMPUTERNAME
$configFolder = ".\ConfigFiles"
$jsonFile = "$configFolder\$hostname.json"
$fileCount = (Get-ChildItem -Path $configFolder -Filter "$hostname*" -File | Measure-Object).Count
if ($fileCount -gt 0) {
    Rename-Item $jsonFile -NewName "$hostname.BK$fileCount.json"
}
Copy-Item "$configFolder\SAMPLE_Config_By_Env_(DuplicateAndRename).json" $jsonFile

# Cargar archivo
$jsonFile = "$configFolder\$hostname.json"
$json = Get-Content $jsonFile | ConvertFrom-Json

# Seteo de configuraciones
$json.EnvironmentId = GetEnvironmentId("AOSService")

$RetailServerURL = GetWebSiteUrl('RetailServer')
$json.RetailServerURL = "$RetailServerURL/RetailServer/Commerce"
$json.CPOSUrl = "$RetailServerURL/POS"
$json.Thumbprint = GetWebSiteCertThumbprint("AOSService")

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
