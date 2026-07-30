param(
    [string]$ImageName = 'localhost:5000/up-test-jenkins:2.568.1-plugins-20260730'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$caPath = Join-Path $projectRoot 'jenkins\certs\company-ca.crt'
$dockerfilePath = Join-Path $projectRoot 'jenkins\Dockerfile'

if (-not (Test-Path -LiteralPath $caPath -PathType Leaf)) {
    throw "社内CA証明書がありません: $caPath"
}

docker build `
    --secret "id=company_ca,src=$caPath" `
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
