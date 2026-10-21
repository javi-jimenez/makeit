# =============================================================================
# makeit — módulo hugo
# -----------------------------------------------------------------------------
# Tareas para sitios Hugo. Requiere el módulo ftp.mk para `deploy`.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   HUGO            binario de Hugo (default: hugo)
#   HUGO_VERSION    versión a instalar en .bin/ (opcional)
#   HUGO_BIN        ruta local del binario (default: ./.bin/hugo)
#   HUGO_PORT       puerto del servidor de desarrollo (default: 1313)
#   HUGO_BASEURL    baseURL del servidor de desarrollo (default: http://localhost:PORT/)
#   HUGO_BUILD_DIR  directorio de salida (default: public)
#   HUGO_DOCKER_IMAGE  imagen oficial usada si no hay binario de Hugo ni en
#                   ./.bin ni en el PATH (patrón D2: nunca instalar en el host)
# =============================================================================

HUGO_BIN        ?= ./.bin/hugo
HUGO_VERSION    ?= 0.152.2
HUGO_PORT       ?= 1313
HUGO_BASEURL    ?= http://localhost:$(HUGO_PORT)/
HUGO_BUILD_DIR  ?= public
HUGO_DOCKER_IMAGE ?= ghcr.io/gohugoio/hugo:latest

# Usa el binario local si existe; si no, el del sistema.
ifeq (,$(wildcard $(HUGO_BIN)))
  HUGO ?= hugo
else
  HUGO ?= $(HUGO_BIN)
endif

# ¿Hay binario de Hugo en el PATH? Si no, se cae a Docker (patrón D2).
# Detección en tiempo de parseo: basta con que Hugo exista en algún sitio.
HUGO_LOCAL := $(shell command -v $(HUGO) >/dev/null 2>&1 && echo 1)

# Ejecuta Hugo con el binario disponible o, si no hay, en el contenedor oficial.
# Uso: $(call hugo_run,--minify --gc)
define hugo_run
if [ -n "$(HUGO_LOCAL)" ]; then \
	$(HUGO) $(1); \
elif command -v docker >/dev/null 2>&1; then \
	printf "$(C_YELL)• Hugo no instalado: usando $(HUGO_DOCKER_IMAGE)$(C_RESET)\n" >&2; \
	docker run --rm -v "$$PWD":/src -w /src $(HUGO_DOCKER_IMAGE) $(1); \
else \
	printf "$(C_RED)✗ Ni Hugo ni Docker disponibles.$(C_RESET)\n"; exit 1; \
fi
endef

# =============================================================================
##@ Hugo
# =============================================================================

.PHONY: hugo-install
hugo-install: ## Descarga Hugo en ./.bin/hugo (Linux x64)
	$(call require_cmd,curl)
	$(call require_cmd,tar)
	@printf "$(C_CYAN)▶ Descargando Hugo v$(HUGO_VERSION)...$(C_RESET)\n"
	@mkdir -p .bin && tmp=$$(mktemp) && \
		curl -L -f -o $$tmp \
			https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_extended_$(HUGO_VERSION)_Linux-64bit.tar.gz && \
		tar -xzf $$tmp -C /tmp && mv /tmp/hugo ./.bin/hugo && chmod +x ./.bin/hugo && rm -f $$tmp
	@$(HUGO_BIN) version

.PHONY: hugo-check
hugo-check: ## Verifica la configuración de Hugo
	@test -f hugo.toml -o -f config.toml || { printf "$(C_RED)✗ No se encuentra hugo.toml/config.toml.$(C_RESET)\n"; exit 1; }
	@$(call hugo_run,config) >/dev/null 2>&1 || { printf "$(C_RED)✗ Error en la configuración de Hugo.$(C_RESET)\n"; exit 1; }
	@printf "$(C_GREEN)✓ Configuración Hugo OK.$(C_RESET)\n"

.PHONY: build
build: hugo-check ## Genera el sitio Hugo en el directorio de salida
	@printf "$(C_CYAN)▶ Generando sitio...$(C_RESET)\n"
	@$(call hugo_run,--minify --cleanDestinationDir --gc)
	@printf "$(C_GREEN)✓ Sitio generado en $(HUGO_BUILD_DIR)/ ($(shell find $(HUGO_BUILD_DIR) -name '*.html' 2>/dev/null | wc -l) páginas).$(C_RESET)\n"

.PHONY: serve
serve: ## Inicia el servidor de desarrollo de Hugo
	@printf "$(C_CYAN)▶ Servidor en $(HUGO_BASEURL)$(C_RESET)\n"
	@if [ -n "$(HUGO_LOCAL)" ]; then \
		$(HUGO) server -D --disableFastRender --navigateToChanged \
			--baseURL="$(HUGO_BASEURL)" --bind="0.0.0.0" --port=$(HUGO_PORT); \
	elif command -v docker >/dev/null 2>&1; then \
		printf "$(C_YELL)• Hugo no instalado: usando $(HUGO_DOCKER_IMAGE)$(C_RESET)\n"; \
		docker run --rm -it -p $(HUGO_PORT):$(HUGO_PORT) \
			-v "$$PWD":/src -w /src $(HUGO_DOCKER_IMAGE) \
			server -D --disableFastRender --navigateToChanged \
			--baseURL="$(HUGO_BASEURL)" --bind="0.0.0.0" --port=$(HUGO_PORT); \
	else \
		printf "$(C_RED)✗ Ni Hugo ni Docker disponibles.$(C_RESET)\n"; exit 1; \
	fi

.PHONY: clean
clean: ## Limpia los artefactos generados (Hugo)
	@rm -rf $(HUGO_BUILD_DIR) resources/_gen .hugo_build.lock
	@printf "$(C_GREEN)✓ Limpieza completada.$(C_RESET)\n"

# `deploy` para Hugo: construye y sube por FTP (requiere el módulo ftp.mk).
ifneq ($(wildcard $(MAKEIT_MODULES)/ftp.mk),)
.PHONY: deploy
deploy: build ftp-upload ## Construye el sitio y lo sube por FTP
endif
