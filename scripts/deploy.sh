#!/bin/bash

set -e # please dont use -x as this will print secrets in the build log

# these env vars can be overridden by circle
CF_API=${CF_API:-https://api.system.staging.digital.gov.au}
CF_ORG=${CF_ORG:-dto}
CF_SPACE=${CF_SPACE:-dfc-test}

# step 1. login to the correct org and space with cf
cf api ${CF_API}
cf auth ${CF_STAGING_USER} ${CF_STAGING_PASSWORD}
cf target -o ${CF_ORG} -s ${CF_SPACE}

# step 2. create db service and app for this branch
CF_APP_NAME=${CIRCLE_PROJECT_REPONAME}-$(git rev-parse --short ${CIRCLE_SHA1})
CF_SERVICE_NAME=${CIRCLE_PROJECT_REPONAME}-$(git rev-parse --short ${CIRCLE_SHA1})-db
cf push ${CF_APP_NAME} --no-start
cf create-service dto-shared-pgsql shared-psql ${CF_SERVICE_NAME}
cf bind-service ${CF_APP_NAME} ${CF_SERVICE_NAME}

# step 3. push branch details into the deployed app's env
if [ -n ${CIRCLE_PR_REPONAME} ] ; then
	cf set-env ${CF_APP_NANE} CIRCLE_PR_REPONAME ${CIRCLE_PR_REPONAME}
fi
if [ -n ${CIRCLE_PR_NUMBER} ] ; then
	cf set-env ${CF_APP_NANE} CIRCLE_PR_NUMBER ${CIRCLE_PR_NUMBER}
fi

# step 4. fire!
cf start ${CF_APP_NAME}
