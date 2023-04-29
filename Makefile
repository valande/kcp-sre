VENV 	?= venv
PYTHON 	= $(VENV)/bin/python3
PYTEST 	= $(VENV)/bin/pytest
PIP		= $(VENV)/bin/pip

# Variables used to configure
IMAGE_REGISTRY_DOCKERHUB 	?= docker.io
IMAGE_REGISTRY_GHCR			?= ghcr.io
IMAGE_REPO					= valande
IMAGE_NAME					?= sre-ss
VERSION						?= dev

# Variables used to configure docker images registries to build and push
IMAGE_LOCAL				= $(IMAGE_NAME):$(VERSION)
IMAGE_DOCKERHUB			= $(IMAGE_REGISTRY_DOCKERHUB)/$(IMAGE_REPO)/$(IMAGE_NAME):$(VERSION)
IMAGE_DOCKERHUB_LATEST	= $(IMAGE_REGISTRY_DOCKERHUB)/$(IMAGE_REPO)/$(IMAGE_NAME):latest
IMAGE_GHCR				= $(IMAGE_REGISTRY_GHCR)/$(IMAGE_REPO)/$(IMAGE_NAME):$(VERSION)
IMAGE_GHCR_LATEST		= $(IMAGE_REGISTRY_GHCR)/$(IMAGE_REPO)/$(IMAGE_NAME):latest


.PHONY: run
run: activate_venv
	$(PYTHON) src/app.py

.PHONY: unit-test
unit-test: activate_venv
	$(PYTEST)

.PHONY: unit-test-coverage
unit-test-coverage: activate_venv
	$(PYTEST) --cov

.PHONY: activate_venv
activate_venv: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt


.PHONY: docker-build
docker-build: ## Build image
	docker build -t $(IMAGE_LOCAL) .

.PHONY: publish
publish: docker-build ## Publish image
	docker tag $(IMAGE_LOCAL) $(IMAGE_DOCKERHUB)
	docker tag $(IMAGE_LOCAL) $(IMAGE_DOCKERHUB_LATEST)
	docker tag $(IMAGE_LOCAL) $(IMAGE_GHCR) 
	docker tag $(IMAGE_LOCAL) $(IMAGE_GHCR_LATEST)
	docker push $(IMAGE_DOCKERHUB)
	docker push $(IMAGE_DOCKERHUB_LATEST)
	docker push $(IMAGE_GHCR)
	docker push $(IMAGE_GHCR_LATEST)
