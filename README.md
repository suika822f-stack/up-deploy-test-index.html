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
