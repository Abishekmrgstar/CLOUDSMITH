resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name

  user_data = <<-EOF
#!/bin/bash
set -o pipefail

dnf update -y

# Install Docker
dnf install docker -y
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install Git
dnf install git -y

# Initial app deployment (keeps app available even if Jenkins seed job has issues)
rm -rf /opt/app
git clone ${var.repo_url} /opt/app
cd /opt/app
cat <<DOCKERFILE > Dockerfile
${var.dockerfile_content}
DOCKERFILE
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi -f app 2>/dev/null || true
docker build --no-cache -t app .
docker run -d -p 80:${var.app_port} app

# Install Java 17 (required for Jenkins)
dnf install java-17-amazon-corretto -y

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
dnf install jenkins -y
usermod -a -G docker jenkins
mkdir -p /var/lib/jenkins/tmp
chown -R jenkins:jenkins /var/lib/jenkins/tmp

# Disable Jenkins setup wizard
mkdir -p /etc/systemd/system/jenkins.service.d
cat <<'JENKINS_OVERRIDE' > /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Djava.io.tmpdir=/var/lib/jenkins/tmp"
Environment="JENKINS_JAVA_OPTIONS=-Djenkins.install.runSetupWizard=false -Dhudson.node_monitors.DiskSpaceMonitor.disabled=true -Dhudson.node_monitors.TemporarySpaceMonitor.disabled=true"
JENKINS_OVERRIDE
systemctl daemon-reload

# Preinstall Jenkins plugins
cat <<'PLUGINS' > /var/lib/jenkins/plugins.txt
workflow-aggregator
git
pipeline-stage-view
docker-workflow
PLUGINS

if command -v jenkins-plugin-cli >/dev/null 2>&1; then
  jenkins-plugin-cli --plugin-file /var/lib/jenkins/plugins.txt || true
elif [ -x /usr/bin/jenkins-plugin-cli ]; then
  /usr/bin/jenkins-plugin-cli --plugin-file /var/lib/jenkins/plugins.txt || true
fi

# Create Jenkins init scripts for admin user and deployment job
mkdir -p /var/lib/jenkins/init.groovy.d

cat <<'SECURITY_GROOVY' > /var/lib/jenkins/init.groovy.d/basic-security.groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.get()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
if (hudsonRealm.getUser("admin") == null) {
    hudsonRealm.createAccount("admin", "admin1234")
}
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.setCrumbIssuer(null)

InstallState.INITIAL_SETUP_COMPLETED.initializeState()
instance.save()
SECURITY_GROOVY

cat <<'JOB_GROOVY' > /var/lib/jenkins/init.groovy.d/create-job.groovy
import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import hudson.slaves.OfflineCause

def instance = Jenkins.get()
instance.setNumExecutors(2)

def builtIn = instance.getComputer("")
if (builtIn != null && builtIn.isTemporarilyOffline()) {
    builtIn.setTemporarilyOffline(false, null)
}

def jobName = "deploy-app"
def pipelineScript = """
pipeline {
  agent any
  triggers {
    pollSCM('H/2 * * * *')
  }
  stages {
    stage('Checkout') {
      steps {
        git url: '${var.repo_url}'
      }
    }
    stage('Deploy') {
      steps {
        sh '''
          docker rm -f \$(docker ps -aq) 2>/dev/null || true
          docker rmi -f app 2>/dev/null || true
          cat > Dockerfile <<'DOCKERFILE'
${var.dockerfile_content}
DOCKERFILE
          docker build --no-cache -t app .
          docker run -d -p 80:${var.app_port} app
        '''
      }
    }
  }
}
"""

try {
    def job = instance.getItem(jobName)
    if (job == null) {
        job = instance.createProject(WorkflowJob, jobName)
    }
    job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
    job.save()
    job.scheduleBuild2(0)
} catch (Exception e) {
  println("Failed to create deploy-app job: $${e.message}")
}

instance.save()
JOB_GROOVY

# Mark setup as completed so unlock page is skipped
mkdir -p /var/lib/jenkins
echo "2.0" > /var/lib/jenkins/jenkins.install.UpgradeWizard.state
echo "2.0" > /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion

chown -R jenkins:jenkins /var/lib/jenkins

# Start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Ensure Jenkins is reachable before seeding job
for i in $(seq 1 60); do
  if curl -fsS http://localhost:8080/login >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

# Wait until admin authentication works
for i in $(seq 1 60); do
  if curl -fsS -u admin:admin1234 http://localhost:8080/api/json >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

# Create/update deploy-app pipeline via Jenkins API (fallback if init.groovy job seed misses)
cat <<'JOBXML' > /tmp/deploy-app.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Auto-created deployment pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/2 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script>pipeline {
  agent any
  stages {
    stage('Checkout') {
      steps {
        git url: '${var.repo_url}'
      }
    }
    stage('Deploy') {
      steps {
        sh '''
          docker rm -f $(docker ps -aq) 2&gt;/dev/null || true
          docker rmi -f app 2&gt;/dev/null || true
          cat &gt; Dockerfile &lt;&lt;'DOCKERFILE'
${var.dockerfile_content}
DOCKERFILE
          docker build --no-cache -t app .
          docker run -d -p 80:${var.app_port} app
        '''
      }
    }
  }
}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
JOBXML

for i in $(seq 1 20); do
  if curl -fsS -u admin:admin1234 http://localhost:8080/job/deploy-app/config.xml >/dev/null 2>&1; then
    curl -fsS -u admin:admin1234 -X POST -H "Content-Type: application/xml" --data-binary @/tmp/deploy-app.xml http://localhost:8080/job/deploy-app/config.xml >/dev/null 2>&1 || true
  else
    curl -fsS -u admin:admin1234 -X POST -H "Content-Type: application/xml" --data-binary @/tmp/deploy-app.xml "http://localhost:8080/createItem?name=deploy-app" >/dev/null 2>&1 || true
  fi

  if curl -fsS -u admin:admin1234 http://localhost:8080/job/deploy-app/api/json >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

# Fallback: write job directly to Jenkins home if API seeding still missed
if ! curl -fsS -u admin:admin1234 http://localhost:8080/job/deploy-app/api/json >/dev/null 2>&1; then
  mkdir -p /var/lib/jenkins/jobs/deploy-app
  cp /tmp/deploy-app.xml /var/lib/jenkins/jobs/deploy-app/config.xml
  chown -R jenkins:jenkins /var/lib/jenkins/jobs/deploy-app
  systemctl restart jenkins

  for i in $(seq 1 60); do
    if curl -fsS -u admin:admin1234 http://localhost:8080/job/deploy-app/api/json >/dev/null 2>&1; then
      break
    fi
    sleep 5
  done
fi

curl -fsS -u admin:admin1234 -X POST http://localhost:8080/job/deploy-app/build >/dev/null 2>&1 || true

EOF

  tags = {
    Name = "Claude-DevOps-Instance"
  }
}