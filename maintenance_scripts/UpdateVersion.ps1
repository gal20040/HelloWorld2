<#
.SYNOPSIS
    Обновляет bundleVersion и AndroidBundleVersionCode в файлах:
    - "ProjectSettings/androidVersionCode.txt"
    - "ProjectSettings/buildVersion.txt"
.DESCRIPTION
    Читает "ProjectSettings/buildVersion.txt", увеличивает указанную часть версии
    (major|minor|patch), пересчитывает bundleVersion и AndroidBundleVersionCode и обновляет файлы.
.PARAMETER Part
    Часть версии для увеличения: major, minor или patch (по умолчанию: patch).
.EXAMPLE
    ./maintenance_scripts/UpdateVersion.ps1 -Part minor
    ./maintenance_scripts/UpdateVersion.ps1 -Part mi
    ./maintenance_scripts/UpdateVersion.ps1 -Part p
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("major","ma","minor","mi","patch","p")]
    [string]$Part = "patch"
)

$androidCodeFilePath = Resolve-Path -Path "ProjectSettings/androidVersionCode.txt" -ErrorAction Stop
$versionFilePath     = Resolve-Path -Path "ProjectSettings/buildVersion.txt"       -ErrorAction Stop

$versionFileContent = Get-Content -Path $versionFilePath -Encoding UTF8 -Raw

if ($versionFileContent -match '(?m)^(\d+)\.(\d+)\.(\d+)$') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
} else {
    Write-Error "Не удалось найти версию в формате X.Y.Z в файле $versionFilePath. Содержимое файла: $versionFileContent"
    exit 1
}

Write-Host "Текущая версия из файла: $major.$minor.$patch" -ForegroundColor Cyan

switch ($Part) {
    {$_ -in "major", "ma"} { $major++ }
    {$_ -in "minor", "mi"} { $minor++ }
    {$_ -in "patch", "p"}  { $patch++ }
}

# Сброс младших разрядов при увеличении старших
if ($Part -in "major", "ma") {
    $minor = 0
    $patch = 0
} elseif ($Part -in "minor", "mi") {
    $patch = 0
}

$newBundleVersion = "$major.$minor.$patch"
Write-Host "Получили новую newBundleVersion: '$newBundleVersion'" -ForegroundColor Green

$newAndroidBundleVersionCode = ($major * 1000000) + ($minor * 1000) + $patch
Write-Host "Получили новую AndroidBundleVersionCode: '$newAndroidBundleVersionCode'" -ForegroundColor Green

Set-Content -Path $androidCodeFilePath -Value $newAndroidBundleVersionCode -Encoding UTF8 -NoNewline
Set-Content -Path $versionFilePath     -Value $newBundleVersion            -Encoding UTF8 -NoNewline

Write-Host "`nВерсия обновлена:" -ForegroundColor Green
Write-Host "  bundleVersion:            $newBundleVersion"
Write-Host "  AndroidBundleVersionCode: $newAndroidBundleVersionCode"

return [PSCustomObject]@{
    AndroidCode  = $newAndroidBundleVersionCode
    BuildVersion = $newBundleVersion
}
