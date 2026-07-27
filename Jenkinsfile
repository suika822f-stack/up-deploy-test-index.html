pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        skipDefaultCheckout(true)
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('GitHubから取得') {
            steps {
                checkout scm
            }
        }

        stage('Apache公開領域へ配置') {
            steps {
                sh '''
                    set -eu
                    test -f index.html
                    find /deploy -mindepth 1 -delete
                    cp -a index.html /deploy/
                '''
            }
        }

        stage('Apache応答確認') {
            steps {
                sh '''
                    set -eu
                    curl --fail --silent --show-error \
                        --retry 5 --retry-delay 2 \
                        http://customer-web/ >/dev/null
                '''
            }
        }
    }

    post {
        success {
            echo '配置とApache応答確認に成功しました。'
        }
    }
}
