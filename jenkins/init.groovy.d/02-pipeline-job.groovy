import hudson.plugins.git.BranchSpec
import hudson.plugins.git.GitSCM
import hudson.plugins.git.UserRemoteConfig
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

def jenkins = Jenkins.get()
def jobName = System.getenv('JENKINS_JOB_NAME') ?: 'github-file-deploy-pipeline'
def repositoryUrl = System.getenv('GITHUB_REPOSITORY_URL')
def branch = System.getenv('GITHUB_BRANCH') ?: 'main'

if (repositoryUrl == null || repositoryUrl.trim().isEmpty()) {
    throw new IllegalStateException('GITHUB_REPOSITORY_URL was not provided.')
}

def job = jenkins.getItem(jobName)
if (job == null) {
    job = jenkins.createProject(WorkflowJob, jobName)

    def remote = new UserRemoteConfig(repositoryUrl, null, null, null)
    def scm = new GitSCM(
        [remote],
        [new BranchSpec("*/${branch}")],
        false,
        [],
        null,
        null,
        []
    )

    def definition = new CpsScmFlowDefinition(scm, 'Jenkinsfile')
    definition.setLightweight(true)
    job.setDefinition(definition)
    job.setDescription('GitHubのJenkinsfileを使用してindex.htmlをApache公開領域へ配置する試験1ジョブ。')
    job.save()

    // 新しいJenkinsホームから作成した場合だけ、試験1を一度実行する。
    job.scheduleBuild2(10)
}

jenkins.save()

