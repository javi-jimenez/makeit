# =============================================================================
# makeit — módulo clean
# -----------------------------------------------------------------------------
# Limpieza genérica de artefactos.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   CLEAN_TARGETS  lista de ficheros/directorios a borrar
#                  (default: artefactos comunes de varios ecosistemas)
# =============================================================================

CLEAN_TARGETS ?= build dist node_modules/.cache .pytest_cache .mypy_cache \
                 __pycache__ *.pyc .DS_Store

# =============================================================================
##@ Limpieza
# =============================================================================

.PHONY: clean-all
clean-all: ## Borra CLEAN_TARGETS (limpieza genérica)
	@printf "$(C_CYAN)▶ Limpiando artefactos...$(C_RESET)\n"
	@for t in $(CLEAN_TARGETS); do rm -rf $$t 2>/dev/null || true; done
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@printf "$(C_GREEN)✓ Limpieza completada.$(C_RESET)\n"
