#!/usr/bin/env bash

# Login to Kubernetes Cluster.
UPDATE_KUBECONFIG_COMMAND="aws eks --region ${AWS_REGION} update-kubeconfig --name ${CLUSTER_NAME}"
if [ -n "$CLUSTER_ROLE_ARN" ]; then
    UPDATE_KUBECONFIG_COMMAND="${UPDATE_KUBECONFIG_COMMAND} --role-arn=${CLUSTER_ROLE_ARN}"
fi
${UPDATE_KUBECONFIG_COMMAND}

# Helm Dependency Update
helm dependency update ${DEPLOY_CHART_PATH:-helm/}

# Helm Deployment
UPGRADE_COMMAND="helm upgrade --install ${DEPLOY_NAME} ${DEPLOY_CHART_PATH:-helm/} --wait --atomic --timeout ${TIMEOUT}"
for config_file in ${DEPLOY_CONFIG_FILES//,/ }
do
    UPGRADE_COMMAND="${UPGRADE_COMMAND} -f ${config_file}"
done
if [ -n "$DEPLOY_NAMESPACE" ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} -n ${DEPLOY_NAMESPACE}"
fi
while [ "$DEPLOY_VALUES" != "$iter" ] ;do
    # extract the substring from start of string up to delimiter.
    iter=${DEPLOY_VALUES%%;;*}
    # delete this first "element" AND next separator, from $IN.
    DEPLOY_VALUES="${DEPLOY_VALUES#$iter;;}"

    UPGRADE_COMMAND="${UPGRADE_COMMAND} --set ${iter}"
done
if [ "$DEBUG" = true ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} --debug"
fi
if [ "$DRY_RUN" = true ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} --dry-run"
fi

echo "Executing: ${UPGRADE_COMMAND}"
${UPGRADE_COMMAND}
