.DEFAULT_GOAL := all
CHART := ccd
RELEASE := chart-${CHART}-release
NAMESPACE := chart-tests
TEST := ${RELEASE}-test-service
ACR := hmctssandbox
AKS_RESOURCE_GROUP := sbox-00-rg
AKS_CLUSTER := sbox-00-aks
HELM_REPO := hmctspublic
ACR_SUBSCRIPTION := DCD-CFTAPPS-SBOX

setup:
	az account set --subscription ${ACR_SUBSCRIPTION}
	az configure --defaults acr=${ACR}
	az acr helm repo add --name ${HELM_REPO}
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER} --overwrite-existing
	helm dependency update ${CHART}

clean:
	-helm delete --purge ${RELEASE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}

lint:
	helm lint ${CHART} --namespace ${NAMESPACE} -f ci-values.yaml

inspect:
	helm inspect chart ${CHART}

deploy:
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} -f ci-values.yaml --wait

upgrade:
	helm upgrade --install ${RELEASE} ${CHART} --namespace ${NAMESPACE} -f ci-values.yaml --wait

test:
	helm test ${RELEASE}

all: setup clean lint deploy test

.PHONY: setup clean lint deploy test all
