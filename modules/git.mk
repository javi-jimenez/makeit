# =============================================================================
# makeit — módulo git
# -----------------------------------------------------------------------------
# Tareas habituales de git: estado, commit, push, pull, tags.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   GIT_REMOTE   remoto por defecto (default: origin)
#   GIT_BRANCH   rama por defecto (default: main)
#   COMMIT_MSG   mensaje de commit por defecto
# La versión del proyecto (para los tags) sale de ./VERSION (ver `make version`).
# =============================================================================

# =============================================================================
##@ Git
# =============================================================================

.PHONY: git-status
git-status: ## Muestra el estado de git
	$(call require_cmd,git)
	@git status --short --branch

.PHONY: git-commit
git-commit: ## Hace commit de todos los cambios (COMMIT_MSG="...")
	$(call require_cmd,git)
	@git add -A; \
	if git diff --cached --quiet; then \
		printf "$(C_YELL)• Sin cambios que commitear.$(C_RESET)\n"; \
	else \
		git commit -m "$(COMMIT_MSG)"; \
		printf "$(C_GREEN)✓ Commit creado.$(C_RESET)\n"; \
	fi

.PHONY: push
push: ## Hace commit de todo y push a GIT_REMOTE/GIT_BRANCH
	$(call require_cmd,git)
	@$(MAKE) git-commit
	@git push "$(GIT_REMOTE)" "$(GIT_BRANCH)"
	@printf "$(C_GREEN)✓ Subido a $(GIT_REMOTE)/$(GIT_BRANCH).$(C_RESET)\n"

.PHONY: pull
pull: ## Hace pull de GIT_REMOTE/GIT_BRANCH
	$(call require_cmd,git)
	@git pull "$(GIT_REMOTE)" "$(GIT_BRANCH)"
	@printf "$(C_GREEN)✓ Actualizado desde $(GIT_REMOTE)/$(GIT_BRANCH).$(C_RESET)\n"

# Etiqueta con timestamp: <version>-YYYYMMDDHHMM (ej: 1.0.1-202610082159).
# La versión sale de ./VERSION (ver `make version`). Si no hay VERSION, solo
# se usa el timestamp.
.PHONY: tag
tag: ## Crea un tag <version>-<timestamp> (versión de ./VERSION)
	$(call require_cmd,git)
	@stamp=$$(date +%Y%m%d%H%M); \
	ver="$(PROJECT_VERSION)"; \
	if [ -n "$$ver" ] && [ "$$ver" != "0.0.0" ]; then tag="$$ver-$$stamp"; else tag="$$stamp"; fi; \
	if git rev-parse "$$tag" >/dev/null 2>&1; then \
		printf "$(C_YELL)• El tag $$tag ya existe.$(C_RESET)\n"; \
	else \
		git tag -a "$$tag" -m "Release $$tag"; \
		printf "$(C_GREEN)✓ Tag $$tag creado.$(C_RESET)\n"; \
	fi

.PHONY: push-tags
push-tags: ## Sube los tags a GIT_REMOTE
	$(call require_cmd,git)
	@git push "$(GIT_REMOTE)" --tags
	@printf "$(C_GREEN)✓ Tags subidos.$(C_RESET)\n"
