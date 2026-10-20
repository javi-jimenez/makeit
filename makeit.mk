# =============================================================================
# makeit — núcleo (core)
# -----------------------------------------------------------------------------
# Framework de Makefiles modulares y reutilizables para cualquier proyecto.
#
# Uso en el Makefile de un proyecto:
#
#   MAKEIT ?= $(HOME)/data/repo/makeit
#   include $(MAKEIT)/makeit.mk
#   include $(MAKEIT)/modules/git.mk
#   include $(MAKEIT)/modules/ftp.mk
#   include $(MAKEIT)/modules/hugo.mk
#
# Cada módulo define targets auto-documentados (##) y agrupados (##@).
# `make help` muestra todo lo disponible.
# =============================================================================

# --- Shell y comportamiento ------------------------------------------------
SHELL := /bin/bash
.DEFAULT_GOAL := help

# Evita que make confunda ficheros con targets y permite encadenar módulos.
MAKEFLAGS += --no-print-directory

# --- Localización de makeit ------------------------------------------------
# MAKEIT se define en el Makefile del proyecto; si no, se asume esta ruta.
MAKEIT ?= $(HOME)/data/repo/makeit
MAKEIT_MODULES ?= $(MAKEIT)/modules

# --- Carga de configuración local ------------------------------------------
# El proyecto puede tener un .env (no versionado) con variables locales.
-include .env
export

# --- Variables comunes (sobreescribibles por el proyecto) -------------------
# Nombre del proyecto (por defecto, el directorio actual).
PROJECT ?= $(notdir $(CURDIR))

# Remoto y rama: acepta GITHUB_REMOTE/GITHUB_BRANCH como alias (compatibilidad).
GIT_REMOTE ?= $(if $(GITHUB_REMOTE),$(GITHUB_REMOTE),origin)
GIT_BRANCH ?= $(if $(GITHUB_BRANCH),$(GITHUB_BRANCH),main)

# Mensaje por defecto de commit.
COMMIT_MSG ?= Automated commit by makeit

# --- Colores (se desactivan si NO_COLOR está definido) ---------------------
ifdef NO_COLOR
  C_RESET :=
  C_BOLD  :=
  C_CYAN  :=
  C_GREEN :=
  C_YELL  :=
  C_RED   :=
else
  C_RESET := \033[0m
  C_BOLD  := \033[1m
  C_CYAN  := \033[36m
  C_GREEN := \033[32m
  C_YELL  := \033[33m
  C_RED   := \033[31m
endif

# --- Helpers internos -------------------------------------------------------
# Comprueba que un comando existe. Uso: $(call require_cmd,git)
define require_cmd
@command -v $(1) >/dev/null 2>&1 || { \
	printf "$(C_RED)✗ Falta el comando '$(1)'.$(C_RESET)\n"; exit 1; }
endef

# Imprime un mensaje de sección.
define section
@printf "\n$(C_BOLD)$(C_CYAN)▶ $(1)$(C_RESET)\n"
endef

# Imprime OK / error.
define ok
@printf "$(C_GREEN)✓ $(1)$(C_RESET)\n"
endef
define fail
@printf "$(C_RED)✗ $(1)$(C_RESET)\n"; exit 1
endef

# --- Versión del proyecto ---------------------------------------------------
# Se guarda en ./VERSION (dentro del proyecto). Si no existe, se asume "0.0.0".
VERSION_FILE ?= VERSION
PROJECT_VERSION := $(shell cat $(VERSION_FILE) 2>/dev/null || echo 0.0.0)

# =============================================================================
##@ Ayuda
# =============================================================================

.PHONY: help
help: ## Muestra esta ayuda
	@printf "\n$(C_BOLD)makeit$(C_RESET) — $(C_CYAN)$(PROJECT)$(C_RESET)\n"
	@printf "Uso: make $(C_CYAN)<target>$(C_RESET)\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n$(C_BOLD)%s$(C_RESET)\n", substr($$0, 5) } \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  $(C_CYAN)%-18s$(C_RESET) %s\n", $$1, $$2 }' \
		$(MAKEFILE_LIST)

.PHONY: version
version: ## Muestra la versión; con VERSION=x.y.z la establece
	@if [ -n "$(VERSION)" ]; then \
		printf "%s\n" "$(VERSION)" > $(VERSION_FILE); \
		printf "$(C_GREEN)✓ Versión del proyecto: $(VERSION)$(C_RESET)\n"; \
	else \
		printf "$(C_BOLD)$(PROJECT)$(C_RESET): $(C_CYAN)$(PROJECT_VERSION)$(C_RESET)\n"; \
		printf "makeit: $(C_CYAN)%s$(C_RESET)\n" "$(shell cat $(MAKEIT)/VERSION 2>/dev/null || echo 'dev')"; \
	fi

.PHONY: version-bump
version-bump: ## Sube la versión automáticamente (BUMP=major|minor|patch)
	@cur="$(PROJECT_VERSION)"; \
	major=$$(echo $$cur | cut -d. -f1); minor=$$(echo $$cur | cut -d. -f2); patch=$$(echo $$cur | cut -d. -f3); \
	case "$(BUMP)" in \
		major) major=$$((major+1)); minor=0; patch=0 ;; \
		minor) minor=$$((minor+1)); patch=0 ;; \
		patch|"") patch=$$((patch+1)) ;; \
		*) printf "$(C_RED)✗ BUMP debe ser major, minor o patch.$(C_RESET)\n"; exit 1 ;; \
	esac; \
	new="$$major.$$minor.$$patch"; \
	printf "%s\n" "$$new" > $(VERSION_FILE); \
	printf "$(C_GREEN)✓ Versión: $$cur → $$new$(C_RESET)\n"
# --- Política de versión visible --------------------------------------------
# Un tag es invisible desde dentro del proyecto. El README lleva la versión
# actual y el CHANGELOG describe cada una. Ver "Política de versión visible"
# en el README de makeit.
README_FILE     ?= README.md
CHANGELOG_FILE  ?= CHANGELOG.md

.PHONY: readme-check
readme-check: ## Comprueba que README y CHANGELOG existen y citan la versión
	@fail=0; \
	for f in $(README_FILE) $(CHANGELOG_FILE); do \
	        if [ ! -f "$$f" ]; then \
	                printf "$(C_RED)✗ Falta %s$(C_RESET)\n" "$$f"; fail=1; \
	        fi; \
	done; \
	ver="$$(cat $(VERSION_FILE) 2>/dev/null || echo 0.0.0)"; \
	if [ "$$ver" != "0.0.0" ]; then \
	        if [ -f "$(README_FILE)" ] && ! grep -qF "$$ver" "$(README_FILE)"; then \
	                printf "$(C_RED)✗ %s no menciona la versión %s$(C_RESET)\n" "$(README_FILE)" "$$ver"; fail=1; \
	        fi; \
	        if [ -f "$(CHANGELOG_FILE)" ] && ! grep -qF "$$ver" "$(CHANGELOG_FILE)"; then \
	                printf "$(C_RED)✗ %s no tiene entrada para %s$(C_RESET)\n" "$(CHANGELOG_FILE)" "$$ver"; fail=1; \
	        fi; \
	fi; \
	if [ "$$fail" -eq 0 ]; then \
	        printf "$(C_GREEN)✓ Versión visible: %s en README y CHANGELOG$(C_RESET)\n" "$$ver"; \
	else \
	        exit 1; \
	fi

.PHONY: changelog-new
changelog-new: ## Prepara la entrada de la versión actual en CHANGELOG.md
	@ver="$$(cat $(VERSION_FILE) 2>/dev/null || echo 0.0.0)"; \
	if [ "$$ver" = "0.0.0" ]; then \
	        printf "$(C_RED)✗ No hay versión. Ejecuta 'make version VERSION=x.y.z' o 'make version-bump'.$(C_RESET)\n"; exit 1; \
	fi; \
	if [ ! -f "$(CHANGELOG_FILE)" ]; then \
	        printf "# Changelog\n\n## [%s] — %s\n\n### Añadido\n\n### Cambiado\n\n### Corregido\n\n### Decidido\n" \
	                "$$ver" "$$(date +%Y-%m-%d)" > "$(CHANGELOG_FILE)"; \
	else \
	        tmp="$$(mktemp)"; \
	        printf "# Changelog\n\n## [%s] — %s\n\n### Añadido\n\n### Cambiado\n\n### Corregido\n\n### Decidido\n\n" \
	                "$$ver" "$$(date +%Y-%m-%d)" > "$$tmp"; \
	        if head -1 "$(CHANGELOG_FILE)" | grep -q '^# Changelog'; then \
	                tail -n +2 "$(CHANGELOG_FILE)" >> "$$tmp"; \
	        else \
	                cat "$(CHANGELOG_FILE)" >> "$$tmp"; \
	        fi; \
	        mv "$$tmp" "$(CHANGELOG_FILE)"; \
	fi; \
	printf "$(C_GREEN)✓ Entrada %s preparada en %s$(C_RESET)\n" "$$ver" "$(CHANGELOG_FILE)"