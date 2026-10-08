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
# =============================================================================

HUGO_BIN        ?= ./.bin/hugo
HUGO_VERSION    ?= 0.152.2
HUGO_PORT       ?= 1313
HUGO_BASEURL    ?= http://localhost:$(HUGO_PORT)/
HUGO_BUILD_DIR  ?= public

# Usa el binario local si existe; si no, el del sistema.
ifeq (,$(wildcard $(HUGO_BIN)))
  HUGO ?= hugo
else
  HUGO ?= $(HUGO_BIN)
endif

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
	@$(HUGO) config >/dev/null 2>&1 || { printf "$(C_RED)✗ Error en la configuración de Hugo.$(C_RESET)\n"; exit 1; }
	@printf "$(C_GREEN)✓ Configuración Hugo OK.$(C_RESET)\n"

.PHONY: build
build: hugo-check ## Genera el sitio Hugo en el directorio de salida
	@printf "$(C_CYAN)▶ Generando sitio...$(C_RESET)\n"
	@$(HUGO) --minify --cleanDestinationDir --gc
	@printf "$(C_GREEN)✓ Sitio generado en $(HUGO_BUILD_DIR)/ ($(shell find $(HUGO_BUILD_DIR) -name '*.html' | wc -l) páginas).$(C_RESET)\n"

.PHONY: serve
serve: ## Inicia el servidor de desarrollo de Hugo
	@printf "$(C_CYAN)▶ Servidor en $(HUGO_BASEURL)$(C_RESET)\n"
	@$(HUGO) server -D --disableFastRender --navigateToChanged \
		--baseURL="$(HUGO_BASEURL)" --bind="0.0.0.0" --port=$(HUGO_PORT)

.PHONY: clean
clean: ## Limpia los artefactos generados (Hugo)
	@rm -rf $(HUGO_BUILD_DIR) resources/_gen .hugo_build.lock
	@printf "$(C_GREEN)✓ Limpieza completada.$(C_RESET)\n"

# `deploy` para Hugo: construye y sube por FTP (requiere el módulo ftp.mk).
ifneq ($(wildcard $(MAKEIT_MODULES)/ftp.mk),)
.PHONY: deploy
deploy: build ftp-upload ## Construye el sitio y lo sube por FTP
endif
