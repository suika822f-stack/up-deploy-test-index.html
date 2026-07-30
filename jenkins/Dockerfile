# syntax=docker/dockerfile:1.7
FROM jenkins/jenkins:2.568.1-jdk21

USER root

# 社内CA証明書は公開リポジトリへ保存せず、Docker Build secretとして受け取る。
# OSの証明書ストアとJenkinsが使用するJavaの証明書ストアへ同じCAを登録する。
RUN --mount=type=secret,id=company_ca,required=true \
    install -m 0644 /run/secrets/company_ca /usr/local/share/ca-certificates/company-ca.crt \
    && update-ca-certificates \
    && keytool -importcert -noprompt -trustcacerts \
        -alias company-ca \
        -file /run/secrets/company_ca \
        -keystore "${JAVA_HOME}/lib/security/cacerts" \
        -storepass changeit

# 直接利用するプラグインと依存プラグインのバージョンをすべて固定する。
COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# 初回起動時に管理者設定とPipelineジョブを自動作成する。
COPY jenkins/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER jenkins

