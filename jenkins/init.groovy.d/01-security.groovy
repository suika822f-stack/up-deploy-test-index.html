import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.security.HudsonPrivateSecurityRealm
import jenkins.install.InstallState
import jenkins.model.Jenkins

def jenkins = Jenkins.get()
def passwordFile = new File('/run/secrets/jenkins_admin_password')

if (!passwordFile.isFile()) {
    throw new IllegalStateException('Jenkins administrator password secret was not provided.')
}

def password = passwordFile.text.trim()
if (password.isEmpty()) {
    throw new IllegalStateException('Jenkins administrator password secret is empty.')
}

if (!(jenkins.securityRealm instanceof HudsonPrivateSecurityRealm)) {
    jenkins.securityRealm = new HudsonPrivateSecurityRealm(false)
}

def realm = (HudsonPrivateSecurityRealm) jenkins.securityRealm
if (realm.getAllUsers().find { it.id == 'admin' } == null) {
    realm.createAccount('admin', password)
}

def authorization = new FullControlOnceLoggedInAuthorizationStrategy()
authorization.setAllowAnonymousRead(false)
jenkins.authorizationStrategy = authorization
jenkins.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
jenkins.save()

