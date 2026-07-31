param(
    [string]$ImageName = 'localhost:5000/up-test-jenkins:2.568.1-plugins-20260731-offline'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$dockerfilePath = Join-Path $projectRoot 'jenkins\Dockerfile.offline'
$downloadScript = Join-Path $PSScriptRoot 'Download-JenkinsPlugins.ps1'

& $downloadScript

docker build `
    --file $dockerfilePath `
    --tag $ImageName `
    $projectRoot

if ($LASTEXITCODE -ne 0) {
    throw 'Jenkinsイメージの作成に失敗しました。'
}

docker push $ImageName

if ($LASTEXITCODE -ne 0) {
    throw 'Jenkinsイメージのローカルレジストリへの登録に失敗しました。'
}

Write-Host "登録完了: $ImageName"
