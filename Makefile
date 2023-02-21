#!/usr/bin/env make

.PHONY: run_website stop_website install_kind create_kind_cluster install_kubectl \
		create_docker_registry connect_registry_to_kind_network connect_registry_to_kind \
		create_kind_cluster_with_registry


run_website:
	docker build -t explorecalifornia.com . && \
		docker run -p 8000:80 -d --name explorecalifornia.com --rm explorecalifornia.com

stop_website:
	docker stop explorecalifornia.com

install_kind:
	curl --location --output ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.17.0/kind-darwin-arm64 && \
		./kind --version

create_kind_cluster: install_kind install_kubectl create_docker_registry
	kind create cluster --name explorecalifornia.com --config ./kind_config.yaml || true && \
		kubectl get nodes

install_kubectl:
	brew install kubectl

create_docker_registry:
	if docker ps | grep -q 'local-registry'; \
	then echo "--> local-registry already created; skipping"; \
	else docker run --name local-registry -d --restart=always -p 5000:5000 registry:2; \
	fi

connect_registry_to_kind_network:
	docker network connect kind local-registry || true

connect_registry_to_kind: connect_registry_to_kind_network
	kubectl apply -f ./kind_configmap.yaml

create_kind_cluster_with_registry:
	$(MAKE) create_kind_cluster && $(MAKE) connect_registry_to_kind

delete_local_registry:
	docker stop -n local-registry && docker rm -n local-registry

delete_kind_cluster: delete_local_registry
	kind delete cluster --name explorecalifornia.com

