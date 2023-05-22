#!/bin/sh -l
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


ACTION=$1
ASK_CONFIG=$2
VERSION=$3
CHART_GIT=$4
CHART_BRANCH=$5
CHART_PATH=$6
JOB_INDEX=$7
HELM_VALUES=$8


export VERSION
export CHART_GIT
export CHART_BRANCH
export CHART_PATH
export REPO_NAME=`echo ${GITHUB_REPOSITORY#*/} | sed -e "s/\//-/g" | cut -c1-36 | tr '[A-Z]' '[a-z]'`
export WORKFLOW_NAME=${GITHUB_WORKFLOW}
export RUN_ID=${GITHUB_RUN_ID}
export YAML_VALUES=`echo "${HELM_VALUES}" | sed -s 's/^/          /g'`

echo "Start test version: ${GITHUB_REPOSITORY}@${VERSION}"

echo "************************************"
echo "*          Set config...           *"
echo "************************************"
mkdir -p ${HOME}/.kube
#kube_config=$(echo "${ASK_CONFIG}" | base64 -di)
#kube_config=$(echo "${ASK_CONFIG}"==== | fold -w 4 | sed '$ d' | tr -d '\n' | base64 --decode)
echo "${ASK_CONFIG}" > ${HOME}/.kube/config
export KUBECONFIG="${HOME}/.kube/config"

VELA_APP_TEMPLATE='
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: ${VELA_APP_NAME}
  description: deploy application ${VELA_APP_NAME}
spec:
  components:
    - name: ${REPO_NAME}
      type: helm
      properties:
        chart: ${CHART_PATH}
        git:
          branch: ${CHART_BRANCH}
        repoType: git
        retries: 3
        url: ${CHART_GIT}
        values:
          namespace: ${env_uuid}
${YAML_VALUES}'

echo -e "${VELA_APP_TEMPLATE}" > ./velaapp.yaml
sed -i '1d' ./velaapp.yaml
cat ./velaapp.yaml

env_uuid=${REPO_NAME}-${GITHUB_RUN_ID}-${JOB_INDEX}
export env_uuid

if [ ${ACTION} == "deploy" ]; then
  echo "************************************"
  echo "*     Create env and deploy...     *"
  echo "************************************"

  echo ${VERSION}: ${env_uuid} deploy start

  vela env init ${env_uuid} --namespace ${env_uuid}

  export VELA_APP_NAME=${env_uuid}
  envsubst < ./velaapp.yaml > velaapp-${REPO_NAME}.yaml
  cat velaapp-${REPO_NAME}.yaml

  vela env set ${env_uuid}
  vela up -f "velaapp-${REPO_NAME}.yaml"

  app=${env_uuid}

  status=`vela status ${app} -n ${app}`
  echo $status
  res=`echo $status | grep "Create helm release successfully"`
  let count=0
  while [ -z "$res" ]
  do
      if [ $count -gt 160 ]; then
        echo "env ${app} deploy timeout..."
        exit 1
      fi
      echo "waiting for env ${app} ready..."
      sleep 5
      status=`vela status ${app} -n ${app}`
      stopped=`echo $status | grep "not found"`
      if [ ! -z "$stopped" ]; then
          echo "env ${app} deploy stopped..."
          exit 1
      fi
      res=`echo $status | grep "Create helm release successfully"`
      let count=${count}+1
  done
fi
