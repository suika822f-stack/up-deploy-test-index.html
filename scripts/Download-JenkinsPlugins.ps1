param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pluginListPath = Join-Path $projectRoot 'jenkins\plugins.txt'
$cachePath = Join-Path $projectRoot 'jenkins\plugins-cache'

if (-not (Test-Path -LiteralPath $pluginListPath -PathType Leaf)) {
    throw "プラグイン一覧がありません: $pluginListPath"
}

New-Item -ItemType Directory -Path $cachePath -Force | Out-Null

$pluginLines = Get-Content -LiteralPath $pluginListPath -Encoding UTF8 |
    Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') }

foreach ($pluginLine in $pluginLines) {
    $parts = $pluginLine.Trim().Split(':', 2)
    if ($parts.Count -ne 2) {
        throw "plugins.txtの形式が不正です: $pluginLine"
    }

    $pluginId = $parts[0]
    $pluginVersion = $parts[1]
    $destination = Join-Path $cachePath "$pluginId.jpi"

    if ((Test-Path -LiteralPath $destination -PathType Leaf) -and -not $Force) {
        Write-Host "取得済み: ${pluginId}:$pluginVersion"
        continue
    }

    $escapedVersion = [Uri]::EscapeDataString($pluginVersion)
    $downloadUrl = "https://updates.jenkins.io/download/plugins/$pluginId/$escapedVersion/$pluginId.hpi"
    $temporaryFile = "$destination.download"

    Write-Host "取得中: ${pluginId}:$pluginVersion"
    curl.exe `
        --fail `
        --location `
        --retry 5 `
        --retry-delay 2 `
        --ssl-no-revoke `
        --output $temporaryFile `
        $downloadUrl

    if ($LASTEXITCODE -ne 0) {
        throw "プラグインの取得に失敗しました: ${pluginId}:$pluginVersion"
    }

    $fileBytes = [System.IO.File]::ReadAllBytes($temporaryFile)
    if ($fileBytes.Length -lt 4 -or $fileBytes[0] -ne 0x50 -or $fileBytes[1] -ne 0x4B) {
        throw "取得ファイルがJenkinsプラグイン形式ではありません: $temporaryFile"
    }

    Move-Item -LiteralPath $temporaryFile -Destination $destination -Force
}

$downloadedCount = (Get-ChildItem -LiteralPath $cachePath -Filter '*.jpi' -File).Count
if ($downloadedCount -ne $pluginLines.Count) {
    throw "プラグイン数が一致しません。一覧=$($pluginLines.Count)、取得済み=$downloadedCount"
}

Write-Host "プラグイン取得完了: $downloadedCount 件"
