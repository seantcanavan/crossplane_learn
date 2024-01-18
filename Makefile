SHELL := /bin/bash

.PHONY: deps helm secret infra resources

all: deps cp_secret infra resources

deps: deps_os deps_docker deps_kind deps_helm

cp: cp_secret cp_provider cp_infra cp_resources


# os-level configuration
deps_os:
	sudo pacman -Syu --needed kubectl helm docker # install packages
	-cp -n cp/aws-credentials.txt.example cp/aws-credentials.txt

# docker configuration
deps_docker:
	sudo systemctl enable docker.service # set the docker service to auto start
	sudo systemctl start docker.service # startup the docker service immediately
	sudo chown $(USER) /var/run/docker.sock # for development purposes only. for prod, create a docker user and run docker images as that user

# helm configuration
deps_helm:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add crossplane-stable https://charts.crossplane.io/stable
	helm repo update
	helm list -n crossplane-system --filter '^crossplane$$' | grep -q 'crossplane' || helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace

# kind  configuration
deps_kind:
	go install sigs.k8s.io/kind@v0.20.0
	kubectl config get-contexts -o name | grep -q 'kind-kind' || kind create cluster

# crossplane provider configuration
cp_provider:
	kubectl apply -f cp/crossplane.yaml
	kubectl apply -f cp/aws_provider.yaml
	kubectl apply -f cp/ddb_provider.yaml
	kubectl apply -f cp/lambda_provider.yaml

cp_secret:
	kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=./cp/aws-credentials.txt
	kubectl describe secret aws-secret -n crossplane-system
	@echo "nicely done! now run 'make infra' next."

cp_infra:
	-#kubectl create -f cp/s3_bucket.yaml
	kubectl apply -f cp/xrd.yaml
	kubectl apply -f cp/template.yaml

cp_resources:
	kubectl apply -f cp/resource.yaml
