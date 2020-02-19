#!/bin/bash -xe

# bootstrapping: if keytab is lost, upload to
# https://codeready-workspaces-jenkins.rhev-ci-vms.eng.rdu2.redhat.com/credentials/store/system/domain/_/
# then set Use secret text above and set Bindings > Variable (path to the file) as ''' + CRW_KEYTAB + '''
chmod 700 ''' + CRW_KEYTAB + ''' && chown ''' + USER + ''' ''' + CRW_KEYTAB + '''
# create .k5login file
echo "crw-build/codeready-workspaces-jenkins.rhev-ci-vms.eng.rdu2.redhat.com@REDHAT.COM" > ~/.k5login
chmod 644 ~/.k5login && chown ''' + USER + ''' ~/.k5login
 echo "pkgs.devel.redhat.com,10.19.208.80 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAplqWKs26qsoaTxvWn3DFcdbiBxqRLhFngGiMYhbudnAj4li9/VwAJqLm1M6YfjOoJrj9dlmuXhNzkSzvyoQODaRgsjCG5FaRjuN8CSM/y+glgCYsWX1HFZSnAasLDuW0ifNLPR2RBkmWx61QKq+TxFDjASBbBywtupJcCsA5ktkjLILS+1eWndPJeSUJiOtzhoN8KIigkYveHSetnxauxv1abqwQTk5PmxRgRt20kZEFSRqZOJUlcl85sZYzNC/G7mneptJtHlcNrPgImuOdus5CW+7W49Z/1xqqWI/iRjwipgEMGusPMlSzdxDX4JzIx6R53pDpAwSAQVGDz4F9eQ==
" >> ~/.ssh/known_hosts

ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# see https://mojo.redhat.com/docs/DOC-1071739
if [[ -f ~/.ssh/config ]]; then mv -f ~/.ssh/config{,.BAK}; fi
echo "
GSSAPIAuthentication yes
GSSAPIDelegateCredentials yes

Host pkgs.devel.redhat.com
User crw-build/codeready-workspaces-jenkins.rhev-ci-vms.eng.rdu2.redhat.com@REDHAT.COM
" > ~/.ssh/config
chmod 600 ~/.ssh/config

# initialize kerberos
export KRB5CCNAME=/var/tmp/crw-build_ccache
kinit "crw-build/codeready-workspaces-jenkins.rhev-ci-vms.eng.rdu2.redhat.com@REDHAT.COM" -kt ''' + CRW_KEYTAB + '''
klist # verify working

hasChanged=0

SOURCEDIR=${WORKSPACE}/sources/dependencies/che-devfile-registry
SOURCEDOCKERFILE=${SOURCEDIR}/Dockerfile
if [[ -f ${SOURCEDIR}/build/dockerfiles/rhel.Dockerfile ]]; then
  SOURCEDOCKERFILE=${SOURCEDIR}/build/dockerfiles/rhel.Dockerfile
fi

# REQUIRE: skopeo
curl -L -s -S https://raw.githubusercontent.com/redhat-developer/codeready-workspaces/master/product/updateBaseImages.sh -o /tmp/updateBaseImages.sh
chmod +x /tmp/updateBaseImages.sh
cd ${WORKSPACE}/sources
  git checkout --track origin/''' + SOURCE_BRANCH + ''' || true
  export GITHUB_TOKEN=''' + GITHUB_TOKEN + ''' # echo "''' + GITHUB_TOKEN + '''"
  git config user.email "nickboldt+devstudio-release@gmail.com"
  git config user.name "Red Hat Devstudio Release Bot"
  git config --global push.default matching
  OLD_SHA=$(git rev-parse HEAD) # echo ${OLD_SHA:0:8}
  pushd ${SOURCEDOCKERFILE%/*} >/dev/null
    /tmp/updateBaseImages.sh -b ''' + SOURCE_BRANCH + ''' -f ${SOURCEDOCKERFILE##*/} # just pass in rhel.Dockerfile
  popd >/dev/null
  NEW_SHA=$(git rev-parse HEAD) # echo ${NEW_SHA:0:8}
  if [[ "${OLD_SHA}" != "${NEW_SHA}" ]]; then hasChanged=1; fi
  SOURCE_SHA=$(git rev-parse HEAD) # echo ${SOURCE_SHA:0:8}
cd ..

# fetch sources to be updated
if [[ ! -d ${WORKSPACE}/target ]]; then git clone ssh://crw-build@pkgs.devel.redhat.com/''' + GIT_PATH + ''' target; fi
cd ${WORKSPACE}/target
  git checkout --track origin/''' + GIT_BRANCH + ''' || true
  git config user.email crw-build@REDHAT.COM
  git config user.name "CRW Build"
  git config --global push.default matching
cd ..