[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

if (!$skipCheckGitRepoUpdated) {
    .\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
}

$GetJsonConfigFile = ".\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\InsertCmmSDKDataInAxDB.ps1 $jsonFile
.\SetApplicationInsightConfig.ps1 $jsonFile