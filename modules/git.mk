# =============================================================================
# makeit — módulo git
# -----------------------------------------------------------------------------
# Tareas habituales de git: estado, commit, push, pull, tags.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   GIT_REMOTE   remoto por defecto (default: origin)
#   GIT_BRANCH   rama por defecto (default: main)
#   COMMIT_MSG   mensaje de commit por defecto
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

.PHONY: tag
tag: ## Crea un tag anotado (TAG=v1.0.0)
	$(call require_cmd,git)
	@test -n "$(TAG)" || { printf "$(C_RED)✗ Define TAG=vX.Y.Z$(C_RESET)\n"; exit 1; }
	@git tag -a "$(TAG)" -m "Release $(TAG)"
	@printf "$(C_GREEN)✓ Tag $(TAG) creado.$(C_RESET)\n"

.PHONY: push-tags
push-tags: ## Sube los tags a GIT_REMOTE
	$(call require_cmd,git)
	@git push "$(GIT_REMOTE)" --tags
	@printf "$(C_GREEN)✓ Tags subidos.$(C_RESET)\n"

.PHONY: release
release: tag push-tags ## Crea un tag (TAG=vX.Y.Z) y lo sube
	@printf "$(C_GREEN)✓ Release $(TAG) publicada.$(C_RESET)\n"
