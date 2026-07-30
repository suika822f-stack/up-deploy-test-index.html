# Jenkins配置試験の再現構成

このリポジトリは、GitHub上の`index.html`をJenkins Pipelineで取得し、AlmaLinux 9上のApacheへ配置する試験1を同じ条件で再現する。

## GitHubで管理するもの

| ファイル | 役割 |
| --- | --- |
| `Jenkinsfile` | GitHubからの取得、`index.html`の配置、Apache応答確認を定義する |
| `jenkins/plugins.txt` | Jenkinsプラグインと依存プラグインのバージョンを固定する |
| `jenkins/Dockerfile` | 社内CAと固定プラグインを組み込んだJenkinsイメージを作る |
| `jenkins/init.groovy.d/01-security.groovy` | 初回起動時にJenkins管理者と認証設定を作る |
| `jenkins/init.groovy.d/02-pipeline-job.groovy` | GitHub上のJenkinsfileを読むPipelineジョブを作る |
| `docker-compose.yml` | Jenkins、Apache、共有ボリュームを同じ構成で起動する |

## GitHubで管理しないもの

次のファイルは機密情報または社内限定情報を含むため、各試験PCへ一度だけ配置する。

| ローカルファイル | 内容 |
| --- | --- |
| `jenkins/certs/company-ca.crt` | 組織が配布する社内CA証明書 |
| `jenkins/secrets/admin-password.txt` | Jenkins管理者`admin`のパスワード |

登録処理と配置場所はGitHubで管理するが、証明書とパスワードの実体は公開しない。

## 初回準備

1. このリポジトリを取得する。
2. 証明書管理者から入手した社内CA証明書を`jenkins/certs/company-ca.crt`へ配置する。
3. Jenkins管理者用のパスワードを`jenkins/secrets/admin-password.txt`へ1行で記載する。
4. リポジトリのルートで次のコマンドを実行する。

```powershell
docker compose up --build -d
```

Jenkinsは初回起動時に次を自動実行する。

1. 固定バージョンのプラグインを読み込む。
2. 管理者`admin`と認証設定を作成する。
3. `github-file-deploy-pipeline`ジョブを作成する。
4. GitHub上の`Jenkinsfile`を読み、試験1を一度実行する。

## 2回目以降の試験

通常は次のコマンドだけで同じ構成を起動できる。

```powershell
docker compose up -d
```

Jenkinsの状態を完全に初期化して、初回状態から再試験する場合は、対象プロジェクトのボリュームを削除してから再作成する。この操作はJenkinsのジョブ履歴を削除するため、必要な記録を保存してから行う。

```powershell
docker compose down -v
docker compose up --build -d
```

イメージ内にプラグイン、CA登録処理、ジョブ自動作成処理が含まれるため、新しいボリュームでも手作業によるプラグイン導入やジョブ作成は不要である。

## 接続先

| 対象 | URL |
| --- | --- |
| Jenkins | `http://localhost:8080` |
| Apache | `http://localhost:8081` |

## 確認

```powershell
docker compose ps
curl.exe --fail http://localhost:8081
```

Jenkinsの`github-file-deploy-pipeline`が`SUCCESS`となり、ApacheからGitHub上の`index.html`が返れば試験成功である。

## ローカルDockerレジストリ

今後のGit管理、Dockerイメージ管理および試験は、作業者PCの次のフォルダーで行う。

```text
C:\Users\matsumoto\Desktop\CICD試験用
```

試験用レジストリは作業者PC内の `localhost:5000` で動作する。外部PCへ公開する本番用レジストリではなく、今回の試験だけに使用する。

| ファイル・場所 | 役割 | Git管理 |
| --- | --- | --- |
| `registry-compose.yml` | ローカルレジストリのコンテナを定義する | 対象 |
| `registry-data` | 登録したDockerイメージの実体を保存する | 対象外 |
| `scripts/Publish-JenkinsImage.ps1` | Jenkinsイメージを作成し、ローカルレジストリへ登録する | 対象 |

レジストリだけを起動する。

```powershell
Set-Location -LiteralPath 'C:\Users\matsumoto\Desktop\CICD試験用'
docker compose -f registry-compose.yml up -d
curl.exe --fail http://localhost:5000/v2/
```

`{}` が返れば、レジストリの基本応答は正常である。

登録済みイメージの一覧を確認する。

```powershell
curl.exe --fail http://localhost:5000/v2/_catalog
```

レジストリを停止する。`registry-data` は削除されないため、登録したイメージは次回起動時にも使用できる。

```powershell
docker compose -f registry-compose.yml down
```

### Jenkinsイメージの登録

社内CA証明書を次の場所に用意してから、登録スクリプトを実行する。

```text
C:\Users\matsumoto\Desktop\CICD試験用\jenkins\certs\company-ca.crt
```

```powershell
.\scripts\Publish-JenkinsImage.ps1
```

このスクリプトは、プラグイン入りJenkinsイメージを作成し、次の名前でローカルレジストリへ登録する。

```text
localhost:5000/up-test-jenkins:2.568.1-plugins-20260730
```

Jenkins管理者パスワードはDockerイメージへ含めない。次のローカルファイルからコンテナ起動時に渡す。

```text
C:\Users\matsumoto\Desktop\CICD試験用\jenkins\secrets\admin-password.txt
```
