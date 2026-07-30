# 社内CA証明書

このディレクトリには、Dockerイメージ作成時に使用する社内CA証明書を次の名前で配置する。

```text
company-ca.crt
```

`company-ca.crt`は組織内で承認された配布元から取得する。ブラウザで表示されたサーバー証明書だけを代用せず、証明書を管理する担当者からCA証明書を入手する。

証明書本体は`.gitignore`の対象であり、公開GitHubへ登録しない。`jenkins/Dockerfile`がDocker Build secretとして証明書を受け取り、次の二つへ登録する。

- Linuxの信頼済みCA証明書ストア
- Jenkinsが使用するJavaの信頼済みCA証明書ストア

