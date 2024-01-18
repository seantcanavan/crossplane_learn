SHELL := /bin/bash

deps:
	# arch packages
	sudo pacman -Syu --needed kubectl helm docker
	# helm configuration
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add crossplane-stable https://charts.crossplane.io/stable
	helm repo update
	helm list -n crossplane-system --filter '^crossplane$$' | grep -q 'crossplane' || helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace
	# docker configuration
	sudo systemctl enable docker.service # set the docker service to auto start
	sudo systemctl start docker.service # startup the docker service immediately
	sudo chown $(USER) /var/run/docker.sock # for development purposes only. for prod, create a docker user and run docker images as that user
	go install sigs.k8s.io/kind@v0.20.0
	kubectl config get-contexts -o name | grep -q 'kind-kind' || kind create cluster
	# crossplane configuration
	kubectl apply -f cp/crossplane.yaml
	kubectl apply -f cp/aws_provider.yaml
	kubectl apply -f cp/ddb_provider.yaml
	kubectl get providers
	kubectl get crds
	-cp -n cp/aws-credentials.txt.example cp/aws-credentials.txt
	@echo "don't forget to set your secret variables! after that, run 'make secret' next."


secret:
	kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=./cp/aws-credentials.txt
	kubectl describe secret aws-secret -n crossplane-system
	@echo "nicely done! now run 'make infra' next."

infra:
	-#kubectl create -f cp/s3_bucket.yaml
	kubectl apply -f cp/xrd.yaml
	kubectl apply -f cp/template.yaml

resources:
	kubectl apply -f cp/resource.yaml
