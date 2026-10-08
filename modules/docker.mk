# =============================================================================
# makeit — módulo docker
# -----------------------------------------------------------------------------
# Construcción y publicación de imágenes Docker.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   DOCKER_IMAGE    nombre de la imagen (default: PROJECT)
#   DOCKER_TAG      tag de la imagen (default: latest)
#   DOCKERFILE      ruta del Dockerfile (default: Dockerfile)
#   DOCKER_REGISTRY registro destino (opcional, ej: ghcr.io/user)
# =============================================================================

DOCKER_IMAGE ?= $(PROJECT)
DOCKER_TAG   ?= latest
DOCKERFILE   ?= Dockerfile

# =============================================================================
##@ Docker
# =============================================================================

.PHONY: docker-build
docker-build: ## Construye la imagen Docker
	$(call require_cmd,docker)
	@docker build -f $(DOCKERFILE) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@printf "$(C_GREEN)✓ Imagen $(DOCKER_IMAGE):$(DOCKER_TAG) construida.$(C_RESET)\n"

.PHONY: docker-push
docker-push: ## Publica la imagen en DOCKER_REGISTRY
	$(call require_cmd,docker)
	@test -n "$(DOCKER_REGISTRY)" || { printf "$(C_RED)✗ Define DOCKER_REGISTRY.$(C_RESET)\n"; exit 1; }
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	@printf "$(C_GREEN)✓ Imagen publicada en $(DOCKER_REGISTRY).$(C_RESET)\n"

.PHONY: docker-run
docker-run: ## Ejecuta la imagen (DOCKER_ARGS="...")
	$(call require_cmd,docker)
	@docker run --rm -it $(DOCKER_ARGS) $(DOCKER_IMAGE):$(DOCKER_TAG)
