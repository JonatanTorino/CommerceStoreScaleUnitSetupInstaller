[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

if (!$skipCheckGitRepoUpdated) {
    .\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
}

$GetJsonConfigFile = ".\Support\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\PreInstall\InsertCmmSDKDataInAxDB.ps1 $jsonFile
.\PreInstall\InsertApplicationInsightConfigInAxDB.ps1 $jsonFile